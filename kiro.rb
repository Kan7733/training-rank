# encoding: utf-8
require 'pg'

db = ENV['DB_NAME']
host = ENV['DB_HOST']
user = ENV['DB_USER']
password = ENV['DB_PASS']
port = ENV['DB_PORT']
conn = PG::Connection.new(host: host, port: port, dbname: db, user: user, password: password)

array = []
num = ""
#テスト
conn.exec_params("select * from tbl_benchpress") do |res|
  res.each do |row|
    if row["contents"] =~ /kg|キロ|ｷﾛ|㌔/
    begin
    row["contents"].each_line{|text|
      if text.include?("ベンチプレス") && text =~ /(kg|キロ|ｷﾛ|㌔)/ 
        kg = $1
        #num = text.slice(/\d*#{$1}/).sub("#{$1}","")
        #num = text.gsub("０-９","0-9").slice(/\d*#{$1}/).sub(/#{$1}/,"")
        num = text.tr("０-９．・","0-9..").slice(/\d*\.*\d*#{$1}/).sub(kg,"")
        p text if num.to_i < 25 && num != ""
        #puts text if num == "kg"
        array << num.to_f unless num.empty?
      end
    }
#      num = row["contents"].slice(/\d*kg/).sub("kg","") if row["contents"].include?("kg")
#      num = row["contents"].slice(/\d*キロ/).sub("キロ","") if row["contents"].include?("キロ")
#      num = row["contents"].slice(/\d*ｷﾛ/).sub("ｷﾛ","") if row["contents"].include?("ｷﾛ")
#      num = row["contents"].slice(/\d*㌔/).sub("㌔","") if row["contents"].include?("㌔")
#      array << num.to_i unless num.empty?
      #p row["contents"]
    rescue => ex
    puts row["contents"]
    #puts num
    puts ex
    exit
    end
    end
  end
end
#puts array.size
p array.sort
