import smtplib
from email.mime.text import MIMEText

mailto_list = ["jiangzijian77@gmail.com"]

mail_host = "smtp.qq.com"
mail_host_port = ["465","587"]
mail_user = "783627014"
mail_pass = "gudjvktedszvbehe"
mail_postfix = "qq.com"

def send_email(to_list, sub, content):
    me = mail_user+"<"+mail_user+"@"+mail_postfix+">"
    msg = MIMEText(content)
    msg['Subject'] = sub
    msg['From'] = me
    msg['To'] = ";".join(to_list)

    try:
        s = smtplib.SMTP_SSL(mail_host+':'+mail_host_port[0])
        s.login(mail_user, mail_pass)
        s.sendmail(me, to_list, msg.as_string())
        s.close()
        return True
    except Exception, e:
        print(str(e))
        return False

if __name__ == '__main__':
    if send_email(mailto_list, "Test", "Appearently you have received message. Exciting"):
        print("Send Success.")
    else:
        print("Send Failed.")