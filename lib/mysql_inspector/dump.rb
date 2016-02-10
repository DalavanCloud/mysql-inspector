module MysqlInspector
  class Dump

    def initialize(dir, *extras)
      @dir = dir
      @extras = extras
    end

    # Public: Get the dump directory.
    #
    # Returns a String.
    attr_reader :dir

    # Public: Delete this dump from the filesystem.
    #
    # Returns nothing.
    def clean!
      FileUtils.rm_rf(dir)
    end

    # Public: Determine if a dump currently exists at the dump directory.
    #
    # Returns a boolean.
    def exists?
      Dir[File.join(dir, "*")].any?
    end

    # Public: Get the tables written by the dump.
    #
    # Returns an Array of MysqlInspector::Table.
    def tables
      Dir[File.join(dir, "*.table")].map { |file| Table.new(File.read(file)) }
    end

    # Public: Write to the dump directory. Any existing dump will be deleted.
    #
    # access - Instance of Access.
    #
    # Returns nothing.
    def write!(access)
      clean! if exists?
      FileUtils.mkdir_p(dir)
      begin
        access.tables.each { |table|
          File.open(File.join(dir, "#{table.table_name}.table"), "w") { |f|
            f.print table.to_simple_schema
          }
        }
        @extras.each { |extra| puts extra.inspect; extra.write!(access) }
      rescue
        FileUtils.rm_rf(dir) # note this does not remove all the dirs that may have been created.
        raise
      end
    end

    # Public: Load this dump into a database. All existing tables will
    # be deleted from the database and replaced by those from this dump.
    #
    # access - Instance of Access.
    #
    # Returns nothing.
    def load!(access)
      schema = tables.map { |t| t.to_sql }.join(";")
      puts schema.inspect
      access.drop_all_tables
      access.load(schema)
      puts "Schema loaded"
      @extras.each { |extra| extra.load!(access) }
    end

  end
end
