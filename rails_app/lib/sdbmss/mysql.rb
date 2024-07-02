
module SDBMSS::Mysql

  # Create MySQL functions used by the system. This code should be
  # written in a way that is safe to run multiple times, so it can be
  # called from a migration (to create the functions in existing
  # databases) as well as from seeds.rb (for new instances of the
  # database).
  #
  # This is compartmentalized here to avoid putting the raw SQL in
  # migrations, which don't get picked up by schema.rb. I tried
  # configuring ActiveRecord to use sql format for its schema files
  # (structure.sql instead of schema.rb) but I couldn't get this to
  # work properly and it is non-standard besides.
  def self.create_functions

    ActiveRecord::Base.connection.execute <<-EOF
DROP FUNCTION IF EXISTS `levenshtein`;
EOF

    ActiveRecord::Base.connection.execute <<-EOF
CREATE FUNCTION `levenshtein`(`s1` VARCHAR(255) CHARACTER SET utf8, `s2` VARCHAR(255) CHARACTER SET utf8)
	RETURNS TINYINT UNSIGNED
	NO SQL
	DETERMINISTIC
BEGIN
	DECLARE s1_len, s2_len, i, j, c, c_temp TINYINT UNSIGNED;
	-- max strlen=255 for this function
	DECLARE cv0, cv1 VARBINARY(256);

	-- if any param is NULL return NULL
  -- (consistent with builtin functions)
  IF s1 = NULL OR s2 = NULL THEN
    RETURN NULL;
  END IF;
  
  SET s1_len = CHAR_LENGTH(s1),
    s2_len = CHAR_LENGTH(s2),
    cv1 = 0x00,
    j = 1,
    i = 1,
    c = 0;

  -- if any string is empty,
  -- distance is the length of the other one

  IF (s1 = s2) THEN
    RETURN 0;
  ELSEIF (s1_len = 0) THEN
    RETURN s2_len;
  ELSEIF (s2_len = 0) THEN
    RETURN s1_len;
  END IF;

  WHILE (j <= s2_len) DO
    SET cv1 = CONCAT(cv1, CHAR(j)),
    j = j + 1;
  END WHILE;

  WHILE (i <= s1_len) DO
    SET c = i,
      cv0 = CHAR(i),
      j = 1;

    WHILE (j <= s2_len) DO
      SET c = c + 1;

      SET c_temp = ORD(SUBSTRING(cv1, j, 1)) -- ord of cv1 current char
        + (NOT (SUBSTRING(s1, i, 1) = SUBSTRING(s2, j, 1))); -- different chars? (NULL-safe)
      IF (c > c_temp) THEN
        SET c = c_temp;
      END IF;

      SET c_temp = ORD(SUBSTRING(cv1, j+1, 1)) + 1;
      IF (c > c_temp) THEN
        SET c = c_temp;
      END IF;

      SET cv0 = CONCAT(cv0, CHAR(c)),
        j = j + 1;
    END WHILE;

    SET cv1 = cv0,
      i = i + 1;
  END WHILE;

	RETURN c;
END;

EOF

    ActiveRecord::Base.connection.execute <<-EOF
DROP FUNCTION IF EXISTS `levenshtein_ratio`;
EOF

    ActiveRecord::Base.connection.execute <<-EOF
CREATE FUNCTION `levenshtein_ratio`(`s1` VARCHAR(255) CHARACTER SET utf8, `s2` VARCHAR(255) CHARACTER SET utf8)
	RETURNS TINYINT UNSIGNED
	DETERMINISTIC
	NO SQL
	COMMENT 'Levenshtein ratio between strings'
BEGIN
	DECLARE s1_len TINYINT UNSIGNED DEFAULT CHAR_LENGTH(s1);
	DECLARE s2_len TINYINT UNSIGNED DEFAULT CHAR_LENGTH(s2);
	RETURN ((levenshtein(s1, s2) / IF(s1_len > s2_len, s1_len, s2_len)) * 100);
END;

EOF

  end

end
