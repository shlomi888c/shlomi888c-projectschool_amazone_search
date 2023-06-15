import mysql.connector
from flask import Flask, render_template, request
from main import scrape_products
import requests
import socket
import os


app = Flask(__name__)



@app.route('/')
def index():
  return render_template('index.html')

@app.route('/search', methods=['GET','POST'])
def search():
  # Get the IP address of the current machine
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  s.connect(("8.8.8.8", 80))
  flask_app_ip = s.getsockname()[0]
  s.close()

  consul_ip = os.environ.get('ip_consul')
  consul_url = f"http://{consul_ip}:8500/v1/agent/service/register"
  data = {
       "ID": "flask-app" + flask_app_ip,
       "Name": "flask-app" + flask_app_ip,
       "Address": flask_app_ip,
       "Port": 5000,
       "Check": {
         "HTTP": f"http://{flask_app_ip}:5000",
         "Interval": "10s"
       }
  }
  response = requests.put(consul_url, json=data)
  
  article_name = request.form['keyword']
  print(article_name)
  user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.50 Safari/537.36'
  url = "https://www.amazon.co.uk"
  product_name, product_price, product_link, product_image = scrape_products(url, user_agent, article_name)
  host_rds = os.environ.get('hostrds')
  # Connect to the RDS instance
  cnx = mysql.connector.connect(
    host=host_rds,
    port=3306,
    database="tutorial",
  # Access the environment variables in your code
    user = os.environ.get('USER'),
    password = os.environ.get('PASSWORD'),
  )

  # Create a cursor
  cursor = cnx.cursor()

  # Execute the CREATE TABLE statement
  table_name = "table_" + article_name.replace(" ", "_")
  cursor.execute("CREATE TABLE {}  (Name VARCHAR(255), Price INT, Link VARCHAR(255), Image VARCHAR(255))".format(table_name))

  # Iterate through the lists and execute an INSERT statement for each element
  for i in range(len(product_name)):
    cursor.execute("INSERT INTO {} (Name, Price, Link, Image) VALUES (%s, %s, %s, %s)".format(table_name),
                   (product_name[i], product_price[i], product_link[i], product_image[i]))


  # Execute a SELECT statement to retrieve the data
  cursor.execute("SELECT * FROM {}".format(table_name))

  # Fetch the rows
  rows = cursor.fetchall()

  # Close the cursor and connection
  cursor.close()
  cnx.close()

  # Render the HTML templates and pass the rows to the templates
  return render_template("display.html", rows=rows)




if __name__ == '__main__':
  app.run(host='0.0.0.0' , debug=True)
