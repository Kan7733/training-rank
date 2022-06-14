require 'pg'

db = ENV['DB_NAME']
host = ENV['DB_HOST']
user = ENV['DB_USER']
password = ENV['DB_PASS']
port = ENV['DB_PORT']
count = 0
conn = PG::Connection.new(host: host, port: port, dbname: db, user: user, password: password)

array = []

conn.exec_params("select * from tbl_benchpress") do |res|
  res.each do |row|
    if row["contents"] =~ /kg/ 
      num = row["contents"].slice(/\d*kg/).sub("kg","")
      array << num.to_i unless num.empty?
      #p row["contents"]
      count += 1
    end  
  end
end

def std(arr_x)
    avg = arr_x.sum / arr_x.length
    arr1 = arr_x.map{|x| (x - avg) ** 2}
    return Math.sqrt(arr1.sum / arr_x.length).round(2)
end

def dev(arr_x)
#標準偏差stdを求める。
    avg = arr_x.sum / arr_x.length
    arr1 = arr_x.map{|x| (x - avg) ** 2}
    std = Math.sqrt(arr1.sum / arr_x.length)
#配列の要素を偏差値に変換して返す。
    return arr_x.map{|x| ((x - avg) * 10 / std + 50).round(2)}
end

array.sort!
#puts array[10..-10]
arr_dev = dev(array[10..-10])
arr_dev.each_with_index do |num,index|
  #puts "偏差値#{num} 値#{array[10..-10][index]}"
end

ave = array.sum.fdiv(array.length)
delete_index = []
array.each_with_index do |n,i|
  hensa_sum = 0
  array_tmp = array.dup
  array_tmp.delete_at(i)
  array_tmp.each do |num|
    hensa = (ave - num)**2
    hensa_sum += hensa
  end
  ave_hensa = hensa_sum.fdiv(array_tmp.length)**(1/2.0)
  #puts ave_hensa,n,"",""
  #if (n - array_tmp.sum.fdiv(array_tmp.length)).abs > ave_hensa
  if n  > (ave_hensa-array_tmp.sum.fdiv(array_tmp.length))*3
    #puts n,i,""
    #array.delete_at(i)
    delete_index << i
  end
end

delete_index.reverse.each{|index|
  #p index
  array.delete_at(index)
}
hensati = dev(array)
array.each_with_index{|num,index|
  puts "値#{num}、偏差値#{hensati[index]}"
}
