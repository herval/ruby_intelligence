def read_data_file(name)
  file = File.open(name)
  
  header = file.gets
  colnames = header.split("\t")[1..-1]
  rownames = []
  data = []

  while (line = file.gets)
    i = line.split("\t")
    rownames << i[0]
    data << i[1..-1].collect { |v| v.to_f }
  end

  return [rownames, colnames, data]
end

def printclust(clust, labels = nil, n = 0)
  # indent to make a hierarchy layout
  res = ""
  res += (' ' * n)
  if clust.id < 0
    # negative id means that this is branch
    res += labels[clust.id]
    # res += '-'
  else
    # positive id means that this is an endpoint
    if labels.nil?
      res += clust.id.to_s
    else 
      res += labels[clust.id]
    end
  end
  puts res

  # now print the right and left branches
  if !clust.left.nil? 
    printclust(clust.left, labels, n+1)
  end

  if !clust.right.nil? 
    printclust(clust.right, labels, n+1)
  end
end