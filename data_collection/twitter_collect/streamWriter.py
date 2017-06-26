import sqlite3


class MyStreamWriter(object):
    
    def __init__(self, dbName, tableName, tableSchema):
        # if not isinstance(tableSchema, dict):
        #     raise ValueError('tableSchema type must be Python dict')
        self.tableName = tableName
        self.tableSchema = tableSchema
        self.insert_values = []
        ## Create database connection
        self.con = sqlite3.connect(dbName)
        self.cur = self.con.cursor()
        ## Construct create table query
        column_string = ', '.join(map(lambda x: x + ' TEXT', self.tableSchema))
        create_table = 'CREATE TABLE IF NOT EXISTS {0} ({1})'.format(self.tableName,
                                                                     column_string)
        ## Create table
        self.cur.execute(create_table)
        self.con.commit()

    def stream_in(self, tableValue, batch=100):
        # if not isinstance(tableValue, dict):
        #     raise ValueError('tableValue type must be Python dict')
        ## Construct insert value query
        value_string = '("' + '","'.join(tableValue) + '")'

        self.insert_values.append(value_string)
        ## Insert into table
        if len(self.insert_values) >= batch:
            insert_values = 'INSERT INTO {0} VALUES {1}'.format(self.tableName,
                                                                ','.join(self.insert_values))
            self.cur.execute(insert_values)
            self.con.commit()
            self.insert_values = []

    def read_table(self):
        self.cur.execute('SELECT * FROM {0}'.format(self.tableName))
        return [tableSchema.keys()] + self.cur.fetchall()

    def disconnect(self):
        self.con.close()


if __name__ == '__main__':
    tableSchema = {'col1': 'TEXT', 'col2': 'TEXT'}
    writer = MyStreamWriter(':memory:', 'test', tableSchema)
    writer.stream_in({'col1': 'aaa', 'col2': 'ccc'})
    writer.stream_in({'col1': 'bbb', 'col2': 'ddd'})
    print writer.read_table()
    writer.disconnect()
    del writer
    