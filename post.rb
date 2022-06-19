class Post

  def self.post_types  # def self.имя_метода - объявление статического метода
    [Memo, Link, Task]
  end

  def self.create(type_index)
    return  post_types[type_index].new
  end

  def initialize
    @created_at = Time.now
    @text = nil
  end

  def read_from_console
    # todo
  end

  def to_strings
    # todo
  end

  def save
    file = File.new(file_path, "w:UTF-8")

    for item in to_strings do
      file.puts(item)
    end

    file.close
  end

  def file_path
    current_path = File.dirname(__FILE__)

    file_name = @created_at.strftime("#{self.class.name}_%Y-%m-%d_%H-%M-%S.txt")

    return current_path + "/" + file_name
  end
end

# PS: Весь набор методов, объявленных в родительском классе называется интерфейсом класса
# Дети могут по–разному реализовывать методы, но они должны подчиняться общей идее
# и набору функций, которые заявлены в базовом (родительском классе)