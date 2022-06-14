require 'pg'

db = ENV['DB_NAME']
host = ENV['DB_HOST']
user = ENV['DB_USER']
password = ENV['DB_PASS']
port = ENV['DB_PORT']
conn = PG::Connection.new(host: host, port: port, dbname: db, user: user, password: password)

array = []

conn.exec_params("select * from tbl_squat") do |res|
#conn.exec_params("select * from tbl_benchpress") do |res|
#conn.exec_params("select * from tbl_deadlift") do |res|
  res.each do |row|
    if row["contents"] =~ /kg|キロ/
      row["contents"]=row["contents"].tr("０-９","0-9")
      num = row["contents"].slice(/\d*kg/).sub("kg","") if row["contents"].include?("kg")
      num = row["contents"].slice(/\d*キロ/).sub("キロ","") if row["contents"].include?("キロ")
      #num = row["contents"].slice(/\d*kg/).sub("kg","")
      #puts row["contents"] if num.to_i < 20
      #next if num.to_i < 20
      #next if num.to_i > 1000
      num = ""
      row["contents"].each_line{|text|
        if text.include?("スクワット") && (text.include?("kg") || text.include?("キロ"))
          num = row["contents"].slice(/\d*kg/).sub("kg","") if row["contents"].include?("kg")
          num = row["contents"].slice(/\d*キロ/).sub("キロ","") if row["contents"].include?("キロ")
        end
      }
      array << num.to_i unless num.empty?
      #p row["contents"]
    end  
  end
end
puts array.sort
exit

#puts array.size
def dev(arr_x)
#標準偏差stdを求める。
    avg = arr_x.sum / arr_x.length
    arr1 = arr_x.map{|x| (x - avg) ** 2}
    std = Math.sqrt(arr1.sum / arr_x.length)
#配列の要素を偏差値に変換して返す。
    return arr_x.map{|x| ((x - avg) * 10 / std + 50).round(2)}
end

#外れ値の算出
def outlier(arr_x)
  #ave = arr_x.sum.fdiv(arr_x.length)
  delete_index = []
  arr_x.each_with_index{|n, i|
    hensa_sum = 0
    array_tmp = arr_x.dup
    array_tmp.delete_at(i)
    ave = array_tmp.sum.fdiv(array_tmp.length)
    array_tmp.each{|num|
      hensa = (ave - num)**2
      hensa_sum += hensa
    }
    ave_hensa = hensa_sum.fdiv(array_tmp.length)**(1/2.0)
    if n > (ave_hensa-array_tmp.sum.fdiv(array_tmp.length))*3
      #puts n,i,(ave_hensa-array_tmp.sum.fdiv(array_tmp.length))*3,ave_hensa,""
      #array.delete_at(i)
      delete_index << i
    end
  }
  return delete_index
end
array.sort!
=begin
outlier(array).reverse.each{|index|
  #p index
  array.delete_at(index)
}
=end
if ARGV[0]
  array << ARGV[0].to_i
end

hensati = dev(array)
array.sort.each_with_index{|num,index|
  break unless ARGV[0]
  if num == ARGV[0].to_i 
    puts "値#{num}、偏差値#{hensati[index]} 順位#{array.size-index}/#{array.size}"
    break
  end
}
