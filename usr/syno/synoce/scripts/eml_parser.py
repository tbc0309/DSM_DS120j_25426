#!/usr/bin/env python
from email import message_from_file
from email.utils import parsedate_tz, mktime_tz, formatdate
from email.header import decode_header
import time
import sys
import os
import json
import re

sys.dont_write_bytecode = True
path = "./msgfiles"

def file_exists (f):
	"""Checks whether extracted file was extracted before."""
	return os.path.exists(os.path.join(path, f))

def save_file (fn, cont):
	"""Saves cont to a file fn"""
	file = open(os.path.join(path, fn), "wb")
	file.write(cont)
	file.close()

def construct_name (id, fn):
	"""Constructs a file name out of messages ID and packed file name"""
	id = id.split(".")
	id = id[0]+id[1]
	return id+"."+fn

def disqo (s):
	"""Removes double or single quotations."""
	s = s.strip()
	if s.startswith("'") and s.endswith("'"): return s[1:-1]
	if s.startswith('"') and s.endswith('"'): return s[1:-1]
	return s

def disgra (s):
	"""Removes < and > from HTML-like tag or e-mail address or e-mail ID."""
	s = s.strip()
	if s.startswith("<") and s.endswith(">"): return s[1:-1]
	return s

def pullout (m, key):
	"""Extracts content from an e-mail message.
	This works for multipart and nested multipart messages too.
	m	-- email.Message() or mailbox.Message()
	key -- Initial message ID (some string)
	Returns tuple(Text, Html, Files, Parts)
	Text  -- All text from all parts.
	Html  -- All HTMLs from all parts
	Files -- Dictionary mapping extracted file to message ID it belongs to.
	Parts -- Number of parts in original message.
	"""
	Html = ""
	Text = ""
	Files = []
	Parts = 0
	if not m.is_multipart():
		if m.get_filename(): # It's an attachment
			fn = m.get_filename()
			cfn = construct_name(key, fn)
			Files.append(fn)
			if file_exists(cfn): return Text, Html, Files, 1
			# save_file(cfn, m.get_payload(decode=True))
			return Text, Html, Files, 1
		# Not an attachment!
		# See where this belongs. Text, Html or some other data:
		cp = m.get_content_type()
		if cp=="text/plain": Text += m.get_payload(decode=True)
		elif cp=="text/html": Html += m.get_payload(decode=True)
		else:
			# Something else!
			# Extract a message ID and a file name if there is one:
			# This is some packed file and name is contained in content-type header
			# instead of content-disposition header explicitly
			cp = m.get("content-type")
			try: id = disgra(m.get("content-id"))
			except: id = None
			# Find file name:
			o = cp.find("name=")
			if o==-1: return Text, Html, Files, 1
			ox = cp.find(";", o)
			if ox==-1: ox = None
			o += 5; fn = cp[o:ox]
			fn = disqo(fn)
			cfn = construct_name(key, fn)
			Files.append(fn)
			if file_exists(cfn): return Text, Html, Files, 1
			# save_file(cfn, m.get_payload(decode=True))
		return Text, Html, Files, 1
	# This IS a multipart message.
	# So, we iterate over it and call pullout() recursively for each part.
	y = 0
	while 1:
		# If we cannot get the payload, it means we hit the end:
		try:
			pl = m.get_payload(y)
		except: break
		# pl is a new Message object which goes back to pullout
		t, h, f, p = pullout(pl, key)
		Text += t; Html += h; Files += f; Parts += p
		y += 1
	return Text, Html, Files, Parts

def extract (msgfile, key):
	"""Extracts all data from e-mail, including From, To, etc., and returns it as a dictionary.
	msgfile -- A file-like readable object
	key		-- Some ID string for that particular Message. Can be a file name or anything.
	Returns dict()
	Keys: from, to, subject, date, text, html, parts[, files]
	Key files will be present only when message contained binary files.
	For more see __doc__ for pullout() and caption() functions.
	"""
	m = message_from_file(msgfile)
	From, To, Subject, Date, CC = caption(m)
	if len(CC) != 0:
		To += "," + CC
	Text, Html, Files, Parts = pullout(m, key)
	Text = Text.strip(); Html = Html.strip()
	from_author, from_mail = format_mail(From)
	to_author, to_mail = format_mail(To)
	Subject = decode_header(Subject)
	msg = {
		"subject": Subject[0][0],
		"from_author": from_author,
		"from_mail": from_mail,
		"to_author": to_author,
		"to_mail": to_mail,
		"date": Date,
		"body": remove_eol(remove_tags(Text) + " " + remove_tags(Html))}
	if Files:
		msg["body"] += " " + " ".join(Files)
	return json.dumps(msg)

def caption (origin):
	"""Extracts: To, From, Subject and Date from email.Message() or mailbox.Message()
	origin -- Message() object
	Returns tuple(From, To, Subject, Date)
	If message doesn't contain one/more of them, the empty strings will be returned.
	"""
	Date = 0
	if origin.has_key("date"):
		Date = get_timestamp(origin["date"].strip())
	From = ""
	if origin.has_key("from"): From = origin["from"].strip()
	To = ""
	if origin.has_key("to"): To = origin["to"].strip()
	CC = ""
	if origin.has_key("cc"): CC = origin["cc"].strip()
	Subject = ""
	if origin.has_key("subject"): Subject = origin["subject"].strip()
	return From, To, Subject, Date, CC

TAG_RE = re.compile(r'<[^>]+>')
def remove_tags(text):
    return TAG_RE.sub(' ', text)

def remove_eol(text):
	res = text.replace("\r\n", " ")
	res = res.replace("\r", " ")
	res = res.replace("\t", " ")
	res = res.replace("\n", " ")
	return res

def get_timestamp(string_date):
	tt = parsedate_tz(string_date)
	return mktime_tz(tt)

def format_mail(inputmails):
	mail_list = inputmails.split(",")
	authors = []
	mails = []
	for each_amil in mail_list:
		author, mail = extract_author_mail(each_amil)
		authors.append(author)
		mails.append(mail)
	return " ".join(authors).strip(), " ".join(mails).strip()

def extract_author_mail(inputmail):
	author = ""
	if inputmail.find("<") > 0:
		author = inputmail[0:inputmail.find("<") - 1]
		author = author.strip()
		mail = inputmail[inputmail.find("<"):len(inputmail)]
	else:
		mail = inputmail
	mail = mail.strip()
	mail = mail.strip("<")
	mail = mail.strip(">")
	return author, mail

def main():
	f = open(sys.argv[1], "rb")
	print extract(f, f.name)
	f.close()

if __name__ == '__main__':
  main()