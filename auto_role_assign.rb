TYPES_ROLES = {
  workshop: "Work", 
  style: "Styl", 
  circle: "Circ", 
  school: "Scho", 
  associate: "Asso", 
  associates: "Assos", 
  atelier: "Atel", 
  artist: "Arti", 
  group: "Grou", 
  styles: "Styl", 
  follower: "Foll", 
  descendant: "Desc", 
  followers: "Foll", 
  contemporary: "Cont", 
  son: "Son", 
  manner: "Mann", 
  miniatures: "Mini", 
  provincial: "Prov", 
  pupil: "Pupi", 
  collaborators: "Coll",
  master: "Mast",
  assistant: "Assi",
  related: "Rela"
}

roles = [ 
  'collaborators',
  'miniatures',
  'followers',
  'associates',
  'styles',
  'circle',
  'school',
  'workshop',
  'associate',
  'atelier',
  'artist',
  'group',
  'follower',
  'descendant',
  'contemporary',
  'son',
  'manner',
  'pupil',
  'master',
  'assistant',
  'related',
  'style'
]

roles.each do |role|
  puts "role: #{role}"
  Name.where("name like '%, #{role}'").each do |name|
    new_name = name.name.gsub(", #{role}", "")
    
    if roles.any? { |role| new_name.include? role } || new_name == name.name
      #go around for another go
    else
      name.entry_artists.each do |entry_artist|
        entry_artist.update_column(:role, role.to_sym)
      end
    end

    matching_names = Name.where("name like ?", new_name)
    # if name already exists!
    

    if matching_names.count == 1
      puts "Merging #{name} into #{matching_names.last}"
      name.merge_into(matching_names.last)
      matching_names.last.update(is_artist: true)
    elsif matching_names.count > 1
      puts "Error: more than one name matches '#{new_name}'"
    else
      name.update_column(:name, new_name)
    end
  end
end