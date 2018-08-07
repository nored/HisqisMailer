#!/usr/bin/env ruby
# Copyright (C) 2018 Klaus Schwarz
# 
# This file is part of HisqisMailer.
# 
# HisqisMailer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# HisqisMailer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with HisqisMailer.  If not, see <http://www.gnu.org/licenses/>.
# 

require 'nokogiri'
require 'mechanize'
require 'diffy'
require 'mail'
require 'optparse'
require 'ostruct'
require 'fileutils'

trap "SIGINT" do
  puts "\nAborting..."
  exit 130
end

options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-p', '--password PASSWORD') { |o| options[:password] = o }
  opt.on('-u', '--username USERNAME') { |o| options[:username] = o }
  opt.on('-s', '--subject MAILSUBJECT') { |o| options[:subject] = o }
end.parse!

@user_name = options.username
@password = options.password
@subject = options.subject.nil? ? "New Grades!" : options.subject

if(@user_name.nil? || @password.nil?)
  abort("Missing password or username")
end

class HisqisMailer
    
    def initialize(user, pass, subject)
      @newValOverview = getValOverwiew(user, pass)
      prettyHtml = %Q(<!DOCTYPE html>
        <html>
          <head>
            <title>Hisqis Mailer - Notenübersicht</title>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link rel="stylesheet" href="assets/css/main.css" />
            <link rel="stylesheet" href="assets/css/bootstrap.min.css" />
            <link rel="stylesheet" href="assets/css/bootstrap-toggle.min.css">
            <script src="assets/js/jquery-3.1.1.min.js"></script>
            <script src="assets/js/jquery.backstretch.min.js"></script>
            <script src="assets/js/bootstrap.min.js"></script>
            <script src="assets/js/bootstrap-toggle.min.js"></script>
          </head>
          <body>
            <script type="text/javascript" language="javascript">
               var min = 1;
               var max = 1084;
        
               function getRandomInt(min, max) {
                  return ~~(Math.random() * (max - min + 1)) + min
              }
        
              $.backstretch([
                    "https://unsplash.it/1920/1080?image=" + getRandomInt(min, max)
                  ]);
            </script>
            <div class="dimmed">
            <form class="form-signin">
              <h2>Notenübersicht</h2>
              <br>
              <br>
              #{@newValOverview}
              </form>
              </div>
            </body>
          </html>
              )
      if(!File.file?(File.join(File.dirname(__FILE__), "html/#{user}-overview.html")))
        File.write(File.join(File.dirname(__FILE__), "html/#{user}-overview.html"), prettyHtml )
        File.write(File.join(File.dirname(__FILE__), "html/#{user}-oldOverview.html"), @newValOverview )
      elsif(!File.file?(File.join(File.dirname(__FILE__), "html/#{user}-oldOverview.html")))
        File.write(File.join(File.dirname(__FILE__), "html/#{user}-oldOverview.html"), @newValOverview )
      else
        @oldValOverview = File.open(File.join(File.dirname(__FILE__), "html/#{user}-oldOverview.html"), "rb") {|io| io.read}
        @diff = Diffy::Diff.new(@newValOverview, @oldValOverview).to_s(:text)
        if(@diff != "")
          puts "Sending Mail..."
          sendMail(user, pass, subject, @newValOverview)
          File.write(File.join(File.dirname(__FILE__), "html/#{user}-oldOverview.html"), @newValOverview )
          File.write(File.join(File.dirname(__FILE__), "html/#{user}-overview.html"), prettyHtml )
        end
      end
      
    end

    def sendMail(user, pass, subject, message)
      mailBody = %Q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
                  <html xmlns="http://www.w3.org/1999/xhtml">
                    <head>
                      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                        <title>#{subject}</title>
                        <style type="text/css">
                          body {margin: 0; padding: 0; min-width: 100%!important;}
                          table {width: 100%; max-width: 600px;}  
                        </style>
                    </head>
                    <body yahoo bgcolor="#f6f8f1">
                      #{message}
                    </body>
                  </html>
                  )

      options = { 
        :address              => "mail.th-brandenburg.de",
        :port                 => 25,
        :user_name            => user,
        :password             => pass,
        :authentication       => 'plain',
        :enable_starttls_auto => true  }
      # Set mail defaults
      Mail.defaults do
        delivery_method :smtp, options
      end
      Mail.deliver do
        to "#{user}@th-brandenburg.de"
        from "#{user}@th-brandenburg.de"
        subject "#{subject}"
        content_type 'text/html; charset=UTF-8'
        body "#{mailBody}"
      end
    end

    def getValOverwiew(user, pass)
        agent = Mechanize.new
        page = agent.get('https://hisqis.fh-brandenburg.de/qisserver/rds?state=user&type=0') 
        # Submit the login form
        hisquisLogin = page.form_with :name => 'loginform'
        hisquisLogin.asdf  = user
        hisquisLogin.fdsa  = pass
        page = hisquisLogin.submit

        # Get Link to valuation overview with correct token
        begin
          page2  = page.link_with(:text => 'Prüfungsverwaltung').click
        rescue
          abort("Hisqis Down, or cannot login...")
        end
        valOverview = page2.link_with(:text => 'Notenspiegel').uri
        # Go to overview page
        overview = agent.get(valOverview)
        # Parse Html
        doc = Nokogiri::HTML(overview.content)
        doc.xpath("//table[2]")
    end
end

def writeIndex
  prettyHtmlHead = %Q(
    <!DOCTYPE html>
    <html>
      <head>
        <title>Hisqis Mailer</title>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="assets/css/main.css" />
        <link rel="stylesheet" href="assets/css/bootstrap.min.css" />
        <link rel="stylesheet" href="assets/css/bootstrap-toggle.min.css">
        <script src="assets/js/jquery-3.1.1.min.js"></script>
        <script src="assets/js/jquery.backstretch.min.js"></script>
        <script src="assets/js/bootstrap.min.js"></script>
        <script src="assets/js/bootstrap-toggle.min.js"></script>
      </head>
      <body>
        <script type="text/javascript" language="javascript">
          var min = 1;
          var max = 1084;

          function getRandomInt(min, max) {
              return ~~(Math.random() * (max - min + 1)) + min
          }

          $.backstretch([
                "https://unsplash.it/1920/1080?image=" + getRandomInt(min, max)
              ]);
        </script>
        <div class="dimmed">
        <form class="form-signin">
          <h2>Available Users</h2>
          <br>
          <br>
  )
  prettyHtmlBody = %Q(
    <a href="#{@user_name}-overview.html" class="btn btn-lg btn-primary btn-block" type="submit">#{@user_name}</a>
  )
  prettyHtmlFooter = %Q(
        </form>
        </div>
      </body>
    </html>
  )
  if(!File.file?(File.join(File.dirname(__FILE__), "html/index.html")) || !File.file?(File.join(File.dirname(__FILE__), "html/index.list")))
    File.write(File.join(File.dirname(__FILE__), "html/index.html"), "")
    File.open(File.join(File.dirname(__FILE__), "html/index.list"), 'a') do |file|
      file.write prettyHtmlBody
    end
    indexList = File.open(File.join(File.dirname(__FILE__), "html/index.list"), "rb") {|io| io.read}
    File.write(File.join(File.dirname(__FILE__), "html/index.html"), "#{prettyHtmlHead}#{indexList}#{prettyHtmlFooter}")
  else
    indexList = File.open(File.join(File.dirname(__FILE__), "html/index.list"), "rb") {|io| io.read}
    if !indexList.include? prettyHtmlBody
      File.open(File.join(File.dirname(__FILE__), "html/index.list"), 'a') do |file|
        file.write prettyHtmlBody
      end
    end
      indexList = File.open(File.join(File.dirname(__FILE__), "html/index.list"), "rb") {|io| io.read}
      File.write(File.join(File.dirname(__FILE__), "html/index.html"), "#{prettyHtmlHead}#{indexList}#{prettyHtmlFooter}")
  end
end

FileUtils.mkdir_p File.join(File.dirname(__FILE__), "html")
run = HisqisMailer.new(@user_name, @password, @subject)
writeIndex()


