import tkinter as tk 
from tkinter import ttk, messagebox
import smtplib
import imaplib
import email
from email.header import decode_header, make_header

# ===== Configuración de Gmail (PON AQUÍ TUS DATOS) =====
GMAIL_SMTP = "smtp.gmail.com"
GMAIL_SMTP_PORT = 587
GMAIL_IMAP = "imap.gmail.com"
GMAIL_IMAP_PORT = 993

EMAIL_ADDRESS = "mariannenicte.rc12@gmail.com"        # <-- tu Gmail
EMAIL_PASSWORD = "sdqxtbwlwrrcjblq"  # <-- tu contraseña de aplicación, sin espacios

def enviar_correo():
    # Usamos tu cuenta real para el envelope sender (lo que Gmail valida)
    from_addr = EMAIL_ADDRESS
    to_addr = entry_destinatario.get().strip()

    # El “Remitente” que pongas en la GUI lo usamos como header (Gmail lo puede reescribir)
    remitente_header = entry_remitente.get().strip() or EMAIL_ADDRESS
    asunto = entry_asunto.get().strip()
    cuerpo = text_mensaje.get("1.0", tk.END).rstrip("\n")

    if not to_addr:
        messagebox.showwarning("Falta destinatario", "Escribe un destinatario.")
        return

    try:
        with smtplib.SMTP(GMAIL_SMTP, GMAIL_SMTP_PORT, timeout=30) as server:
            server.ehlo()
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)

            # Construimos un mensaje con headers correctos
            mensaje_email = (
                f"From: {remitente_header}\r\n"
                f"To: {to_addr}\r\n"
                f"Subject: {asunto}\r\n"
                "MIME-Version: 1.0\r\n"
                "Content-Type: text/plain; charset=utf-8\r\n"
                "\r\n"
                f"{cuerpo}"
            )

            server.sendmail(from_addr, [to_addr], mensaje_email.encode("utf-8"))

        messagebox.showinfo("Éxito", "Correo enviado correctamente")
    except Exception as e:
        messagebox.showerror("Error", f"Error al enviar el correo:\n{e}")

def recibir_correos():
    try:
        mail = imaplib.IMAP4_SSL(GMAIL_IMAP, GMAIL_IMAP_PORT)
        mail.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        mail.select("INBOX")  # usa "INBOX" en mayúsculas para Gmail

        typ, data = mail.search(None, "ALL")
        if typ != "OK" or not data or not data[0]:
            text_recibidos.delete("1.0", tk.END)
            text_recibidos.insert(tk.END, "No hay correos en la bandeja.")
            mail.logout()
            return

        mail_ids = data[0].split()
        mensajes = []

        # Leer los últimos 5 correos (del más reciente al más antiguo)
        for num in reversed(mail_ids[-5:]):
            typ, msg_data = mail.fetch(num, "(RFC822)")
            if typ != "OK":
                continue

            for response_part in msg_data:
                if not isinstance(response_part, tuple):
                    continue
                msg = email.message_from_bytes(response_part[1])

                # Decodificar asunto y remitente correctamente
                raw_subject = msg.get("Subject", "")
                subject = str(make_header(decode_header(raw_subject)))
                from_ = str(make_header(decode_header(msg.get("From", ""))))
                date_ = msg.get("Date", "")

                # Cuerpo: preferimos text/plain
                body_text = ""
                if msg.is_multipart():
                    for part in msg.walk():
                        ctype = part.get_content_type()
                        disp = str(part.get("Content-Disposition", ""))
                        if ctype == "text/plain" and "attachment" not in disp:
                            try:
                                body_text = part.get_payload(decode=True).decode(part.get_content_charset() or "utf-8", errors="replace")
                            except Exception:
                                body_text = part.get_payload(decode=True).decode("utf-8", errors="replace")
                            break
                else:
                    payload = msg.get_payload(decode=True)
                    if payload:
                        try:
                            body_text = payload.decode(msg.get_content_charset() or "utf-8", errors="replace")
                        except Exception:
                            body_text = payload.decode("utf-8", errors="replace")

                # Recorte para no saturar la GUI
                if len(body_text) > 1000:
                    body_text = body_text[:1000] + "\n…(recortado)…"

                mensajes.append(
                    f"De: {from_}\nAsunto: {subject}\nFecha: {date_}\n\n{body_text}\n" +
                    "-"*60 + "\n"
                )

        text_recibidos.delete("1.0", tk.END)
        text_recibidos.insert(tk.END, "".join(mensajes) if mensajes else "No hay correos nuevos.")

        try:
            mail.close()
        except Exception:
            pass
        mail.logout()

    except Exception as e:
        messagebox.showerror("Error", f"Error al recibir correos:\n{e}")

# ===== Interfaz gráfica =====
ventana = tk.Tk()
ventana.title("Correo Gmail")

# Remitente visible (header), por defecto tu Gmail
ttk.Label(ventana, text="Remitente (header):").grid(row=0, column=0, sticky=tk.W)
entry_remitente = ttk.Entry(ventana, width=50)
entry_remitente.insert(0, EMAIL_ADDRESS)  # autocompletar
entry_remitente.grid(row=0, column=1)

ttk.Label(ventana, text="Destinatario:").grid(row=1, column=0, sticky=tk.W)
entry_destinatario = ttk.Entry(ventana, width=50)
entry_destinatario.grid(row=1, column=1)

ttk.Label(ventana, text="Asunto:").grid(row=2, column=0, sticky=tk.W)
entry_asunto = ttk.Entry(ventana, width=50)
entry_asunto.grid(row=2, column=1)

ttk.Label(ventana, text="Mensaje:").grid(row=3, column=0, sticky=tk.W)
text_mensaje = tk.Text(ventana, width=50, height=10)
text_mensaje.grid(row=3, column=1)

ttk.Button(ventana, text="Enviar", command=enviar_correo).grid(row=4, column=1, sticky=tk.E, pady=4)
ttk.Button(ventana, text="Recibir Correos", command=recibir_correos).grid(row=5, column=0, sticky=tk.W, pady=4)

text_recibidos = tk.Text(ventana, width=80, height=20)
text_recibidos.grid(row=6, column=0, columnspan=2, pady=6)

ventana.mainloop()
