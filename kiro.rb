# encoding: utf-8
require 'pg'

db = ENV['DB_NAME']
host = ENV['DB_HOST']
user = ENV['DB_USER']
password = ENV['DB_PASS']
port = ENV['DB_PORT']
conn = PG::Connection.new(host: host, port: port, dbname: db, user: user, password: password)
case ARGV[0]
when "ベンチプレス"
  event = ARGV[0]
  tbl = "tbl_benchpress"
when "スクワット"
  event = ARGV[0]
  tbl = "tbl_squat"
when "デッドリフト"
  event = ARGV[0]
  tbl = "tbl_deadlift"
else
  puts "引数1:種目名(ベンチプレスorスクワットorデッドリフト)"
  puts "引数2:種目の重量を半角数字で(例100)"
exit
end

array = []
num = ""
#テスト
conn.exec_params("select * from #{tbl}") do |res|
  res.each do |row|
    if row["contents"] =~ /kg|キロ|ｷﾛ|㌔/
    begin
    row["contents"].gsub("。","\n").each_line{|text|
      if text.include?(event) && text =~ /(kg|キロ|ｷﾛ|㌔|㎏)/
        kg = $1
        num = text.tr("０-９．・","0-9..").gsub(/\s#{kg}|　#{kg}/,"#{kg}").scan(/\d*\.*\d*#{kg}/)
        tmp = 0
        num.each {|x| tmp = x.sub(kg,"").to_f if tmp < x.sub(kg,"").to_f}
        #puts text,tmp if tmp == 1000.0 || tmp ==330.0||tmp ==350.0||tmp ==365.0||tmp ==500.0||tmp ==560.0||tmp ==1000.0||tmp ==1110.0||tmp ==5000.0
        #puts text,tmp if tmp > 200.0
        array << tmp unless tmp < 20
      end
    }
#      num = row["contents"].slice(/\d*kg/).sub("kg","") if row["contents"].include?("kg")
#      num = row["contents"].slice(/\d*キロ/).sub("キロ","") if row["contents"].include?("キロ")
#      num = row["contents"].slice(/\d*ｷﾛ/).sub("ｷﾛ","") if row["contents"].include?("ｷﾛ")
#      num = row["contents"].slice(/\d*㌔/).sub("㌔","") if row["contents"].include?("㌔")
#      array << num.to_i unless num.empty?
      #p row["contents"]
    rescue => ex
    #puts row["contents"]
    #puts num
    puts ex.backtrace
    exit
    end
    end
  end
end
#puts array.size
array.sort!

def dev(arr_x)
#標準偏差stdを求める。
    avg = arr_x.sum / arr_x.length
    arr1 = arr_x.map{|x| (x - avg) ** 2}
    std = Math.sqrt(arr1.sum / arr_x.length)
#配列の要素を偏差値に変換して返す。
    return arr_x.map{|x| ((x - avg) * 10 / std + 50).round(2)}
end


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
      #hensa = (ave - num)
      hensa_sum += hensa
    }
    ave_hensa = hensa_sum.fdiv(array_tmp.length)**(1/2.0)
    if n > (array_tmp.sum.fdiv(array_tmp.length) + ave_hensa*4)
      #puts n,i,(ave_hensa-array_tmp.sum.fdiv(array_tmp.length))*3,ave_hensa,""
      #array.delete_at(i)
      delete_index << i
    end
  }
  return delete_index
end

loop do
  array_tmp = []
  outlier(array).reverse.each{|index|
    array_tmp = array.dup
    array.delete_at(index)
  }
  break if array_tmp.empty?
end

if ARGV[1]
  array << ARGV[1].to_i
end

hensati = dev(array)
array.sort.each_with_index{|num,index|
  break unless ARGV[1]
  if num == ARGV[1].to_i
    puts "値#{num}、偏差値#{hensati[index]} 順位#{array.size-index}/#{array.size}"
    break
  end
}
