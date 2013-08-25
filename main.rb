#! ruby -Ku

# To change this template, choose Tools | Templates
# and open the template in the editor.
require "kconv"

require 'rexml/document'
require 'fileutils'
require 'kconv'

def search_mp4_base(pattern)
  result = nil;
  Dir.glob(pattern) {
    |filename_mp4|
    #puts "found " + filename_mp4
    base_name = File.basename(filename_mp4, ".mp4")
    #puts "base = " + base_name
    result = base_name

    }
  return result
end

def search_comment_file_name(number)
  result = nil
  puts "number of com = " + number
  pat = number + "_thread_" + number + ".xml"
  puts "comment pat = " + pat
  Dir.glob(pat) { |filename|
    result = filename
  }
  if result == nil then
    name_paly_info = "*" + number + "_play_info.txt"
    Dir.glob(name_paly_info) { |tmpname|
      name_paly_info = tmpname
      puts "found " + name_paly_info
      file_play_info = open(name_paly_info)
      contents_play_info = ""
      for x in file_play_info
        contents_play_info = contents_play_info + x
      end
      file_play_info.close()
      puts contents_play_info + "\n"
      params = contents_play_info.split("&")
      for values in params do
        if /thread_id=([0-9]+)/ =~ values then
          puts "found thread_id " + $1
          pat = "sm" + number + "_thread_" + $1 + ".xml"
          if File.exist?(pat) then
            result = pat
          end
          break
        end
      end
      break;
    }
  end
  return result
end

def search_comment_file_number(meta_name)
  result = nil
  rgx = Regexp.new("[0-9]+")
  m = rgx.match(meta_name)
  if m.length > 0 then
    result = m[0]
  end
  return result
end

def move_to_folders(number)
  # 「dust」というフォルダがある場合
  # mata_info.xmlおよびplay_info.txtを
  # dustというフォルダに移動します
  if File.exist?("dust") then
    ar_trash = ["_meta_info.xml", "_play_info.txt", "__log__.log", "_thread_*.xml"]
    for name in ar_trash do
      file_name = "*" + number + name
      Dir.glob(file_name) { |tmpname|
        file_name = tmpname
        FileUtils.mv file_name, "dust/" + file_name
        break;
      }
    end
  end
end

def move_series_folders
  puts "シリーズフォルダ検索"
  # たとえば「smxxxxx_video_シリーズ名＋その他文字列.mp4」と
  # 「smxxxxx_video_シリーズ名＋その他文字列.xml」というファイルになる
  # 動画のシリーズがあったとします。
  # このとき「series_シリーズ名」というフォルダを用意しておくと
  # mp4とxmlをそちらに移動します。

  tag_dir = "series_"
  Dir.glob(tag_dir + "*") {
    |filename|
    #puts filename
    is_end = false
    if File.ftype(filename) == "directory" then
      if /series_(.*)/ =~ filename then
        series_name = $1
        pat = "*.*"
        puts pat
        Dir.glob(pat) {
          |filename_for_move|
          reg = Regexp.compile("[a-z]+[0-9]+[_a-z]+" + series_name + ".*")
          if reg =~ filename_for_move then
            puts "移動ターゲット = " + filename_for_move
            FileUtils.mv filename_for_move, filename + "/" + filename_for_move
          end
        }
        #puts "シリーズ名 " + $1
      else
        #puts "not シリーズ名 " + filename
      end
    else
      #puts "not dir " + filename

    end
    if is_end then
      break
    end
  }
end

puts "Hello World"
puts "2nd message"
str = "string"
puts str
#TODO check
#Dir::chdir("Z:/Documents/NetBeansProjects/RubyApplication1/lib")
puts Dir::pwd
meta_info_pattern = "*_meta_info.xml"
Dir.glob(meta_info_pattern) {
  |filename_meta_info|

  puts filename_meta_info
  xml = open(filename_meta_info) {|f| f.read}
  doc = REXML::Document.new(xml)

  #puts doc
  video_id = doc.elements['/nicovideo_thumb_response/thumb/video_id'].text
  puts "video_id = " + video_id
  title = doc.elements['/nicovideo_thumb_response/thumb/title'].text
  puts "title = " + title
  mp4_pattern = video_id + "*.*"
  puts mp4_pattern
  mp4_base_name = search_mp4_base(mp4_pattern)
  if mp4_base_name != nil then
    puts "found mp4 " + mp4_base_name
    meta_number = search_comment_file_number(filename_meta_info)
    if meta_number != nil then
      puts "meta_number = " + meta_number
      file_name_com = search_comment_file_name(meta_number)
      if file_name_com != nil then
        puts "found comment = " + file_name_com
        name_new = mp4_base_name + ".xml"
        puts "rename " + file_name_com + "=>" + name_new
        File.rename(file_name_com, name_new)
      else
        puts "can not found comment of " + meta_number
      end
      #フォルダへ移動
      puts "meta_number = " + meta_number
      move_to_folders(meta_number)
    else
      puts "can not found meta_number of " + filename_meta_info
    end
  else
    puts "can not found mp4 pttern of " + mp4_pattern
  end


}
move_series_folders()

puts "end"
