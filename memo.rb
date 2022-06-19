class Memo < Post

  def read_from_console
    puts "Новая заметка (все, что пишете до строчик \"end\"):"

    @text = []

    line = nil

    while line != "end" do
      line = STDIN.gets.chomp
      @text << line
    end
    @text.pop
  end

  def to_strings
    time_string = "Создано: #{@created_at.strftime("%Y.%m.%d, %H:%M:%S")} \n\r \n\r"

    return @text.unshift(time_string)
    # unshift Добавляет в начало массива строчку time_string и возвращает текст
    # + строчка time_string в нчало массива
  end
end