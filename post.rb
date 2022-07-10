require 'sqlite3'

class Post

  @@SQLITE_DB_FILE = 'notepad.db'

  def self.post_types  # def self.имя_метода - объявление статического метода
    {"Memo" => Memo, "Task" => Task, "Link" => Link}
  end

  def self.create(type)
    return  post_types[type].new
  end

  def self.find(limit, type, id)

    db = SQLite3::Database.open(@@SQLITE_DB_FILE) # открываем "соединение" к базе SQLite
    if !id.nil?
      db.results_as_hash = true # настройка соединения к базе, он результаты из базы преобразует в Руби хэши
      # выполняем наш запрос, он возвращает массив результатов, в нашем случае из одного элемента
      result = db.execute("SELECT * FROM posts WHERE  rowid = ?", id)
      # получаем единственный результат (если вернулся массив)
      result = result[0] if result.is_a? Array
      db.close

      if result.empty?
        puts "Такой id #{id} не найден в базе :("
        return nil
      else
        # создаем с помощью нашего же метода create экземпляр поста,
        # тип поста мы взяли из массива результатов [:type]
        # номер этого типа в нашем массиве post_type нашли с помощью метода Array#find_index
        post = create(result['type'])

        #   заполним этот пост содержимым
        post.load_data(result)

        # и вернем его
        return post
      end

      # эта ветвь выполняется если не передан идентификатор
    else

      db.results_as_hash = false # настройка соединения к базе, он результаты из базы НЕ преобразует в Руби хэши

      # формируем запрос в базу с нужными условиями
      query = "SELECT rowid, * FROM posts "

      query += "WHERE type = :type " unless type.nil? # если задан тип, надо добавить условие
      query += "ORDER by rowid DESC " # и наконец сортировка - самые свежие в начале

      query += "LIMIT :limit " unless limit.nil? # если задан лимит, надо добавить условие

      # готовим запрос в базу, как плов :)
      statement = db.prepare query

      statement.bind_param('type', type) unless type.nil? # загружаем в запрос тип вместо плейсхолдера, добавляем лук :)
      statement.bind_param('limit', limit) unless limit.nil? # загружаем лимит вместо плейсхолдера, добавляем морковь :)

      result = statement.execute! #(query) # выполняем
      statement.close
      db.close


      return result
    end
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

  def save_to_db
    db = SQLite3::Database.open(@@SQLITE_DB_FILE)

    db.results_as_hash = true

    db.execute(
        "INSERT INTO posts (" +
            to_db_hash.keys.join(',') +
            ")" +
            "VALUES (" +
            ("?,"*to_db_hash.keys.size).chomp(',') +
            ")",
        to_db_hash.values
    )

    insert_row_id = db.last_insert_row_id
    db.close

    return  insert_row_id
  end

  def to_db_hash
    {
        'type' => self.class.name,
        'created_at' => @created_at.to_s
    }
  end

  def load_data(data_hash)
    @created_at = Time.parse(data_hash['created_at'])
  end
end

# PS: Весь набор методов, объявленных в родительском классе называется интерфейсом класса
# Дети могут по–разному реализовывать методы, но они должны подчиняться общей идее
# и набору функций, которые заявлены в базовом (родительском классе)