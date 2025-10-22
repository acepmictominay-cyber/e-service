import mysql.connector

conn = mysql.connector.connect(host='localhost', user='root', password='', database='azzahra2_multibrand')
cursor = conn.cursor()
cursor.execute("UPDATE produk SET gambar = NULL")
conn.commit()
print("Gambar di database telah dikosongkan")
conn.close()
