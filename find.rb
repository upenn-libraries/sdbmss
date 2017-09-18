N = 100
fields = Entry.first.as_flat_hash.map{ |key, value| [key, [0, 0]]}.to_h

EntryManuscript.first(N).each do |em|
  em.manuscript.entries.each do |entry|
    if entry.id != em.entry.id
      e1 = entry.as_flat_hash
      e2 = em.entry.as_flat_hash
      e1.each do |k, v|
        fields[k] = [Levenshtein.normalized_distance(e1[k].to_s, e2[k].to_s), fields[k][1] + 1]
      end
    end
  end
end

puts fields.map{ |key, value| [key, (value[0] / value[1])]}.to_h.sort_by{ |key, value| value }.to_h
