require 'csv'
require 'sunlight/congress'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  unless phone_number.nil?
    number = phone_number.scan(/\d+/).join
    if (number.length == 10) || (number.length == 11 && number[0] == '1')
      return number.length == 11 ? number[1..-1] : number
    end
  end
  'Invalid Number'
end

def dates(cvs_obj)
  cvs_obj.collect do |row|
    DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
  end
end

def hours(dates)
  dates.collect(&:hour)
end

def days(dates)
  dates.collect { |date| date.strftime('%A') }
end

def peaks(values)
  value_counts = []
  values.map do |x|
    value_counts << [x, values.count(x)]
  end
  sort_and_remove_duplicates(value_counts).reverse
end

def sort_and_remove_duplicates(value_counts)
  value_counts.sort_by! { |_value, count| count }
  value_counts.map! do |value, count|
    "#{value}: #{count}"
  end
  value_counts.uniq
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exist? 'output'

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager Initialized!'

contents = CSV.open '/home/briggs/workspace/event-manager/event_ettendees.csv',
                    headers: true, header_converters: :symbol

template_letter = File.read '/home/briggs/workspace/event-manager/form_letter.erb'
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
  puts phone_number.to_s
end

puts peaks(days(dates(contents)))
