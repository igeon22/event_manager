require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_number(phone_number)
  if phone_number.length == 10 
    phone_number
  elsif phone_number.length == 11 and phone_number[0] == 1
    phone_number[0] = ''
  else
    phone_number = 'Not valid'
  end
  phone_number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def get_peak_hours(contents)
  all_hours = []
  contents.each do |row|
    all_hours.push(DateTime.strptime(row[:regdate], "%m/%d/%y  %H:%M").strftime("%H"))
  end
  hour_counts = Hash.new(0)
  all_hours.each { |hour| hour_counts[hour] += 1 }

  max_counts = hour_counts.values.max
  # puts max_counts
  peak_hours = hour_counts.each.select { |hour, count | count == max_counts}.map { |key, value| key }
  puts "Peak hours: #{peak_hours.join('-')}"
end

def get_peak_days(contents)
  all_days = []
  contents.each do |row|
    all_days.push(DateTime.strptime(row[:regdate], "%m/%d/%y  %H:%M").strftime("%A"))
  end
  day_counts = Hash.new(0)
  all_days.each { |day| day_counts[day] += 1 }
  max_counts = day_counts.values.max
  # puts max_counts
  peak_days = day_counts.each.select { |day, count | count == max_counts}.map { |key, value| key }
  peak_days
  puts "Peak days: #{peak_days.join('-')}"
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
content_result = []
contents.each  { |row| content_result.push(row) }


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

get_peak_hours(content_result)
get_peak_days(content_result)
gg = contents.clone
# p peak_hours

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = row[:homephone]

  phone_number = phone_number.gsub(/[^0-9]/,'')
  phone_number = clean_number(phone_number)

  regdate = row[:regdate]
  date = regdate[0]
  time = regdate[0]
  
 
  

  
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id,form_letter)
end
