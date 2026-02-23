import tkinter as tk 
from tkinter import filedialog, messagebox, simpledialog
from datetime import datetime
import random 
import ollama

# --- AI FUNCTIONS ---

def ai_enhance(task_type):
    """Handles all AI logic: Extend, Shorten, or Fix Grammar"""
    original_text = text_area.get(1.0, tk.END).strip()
    
    if not original_text:
        messagebox.showwarning("Warning", "The editor is empty!")
        return

    # For extend/shorten, we ask for a word count
    word_count = ""
    if task_type in ["extend", "shorten"]:
        word_count = simpledialog.askstring("Input", f"How many words should the result be?")
        if not word_count: return
        prompt = f"{task_type.capitalize()} the following text to approximately {word_count} words. Output ONLY the modified text:\n\n{original_text}"
    else:
        prompt = f"Fix grammar and spelling mistakes in the following text. Output ONLY the corrected text:\n\n{original_text}"

    try:
        # Show a temporary "Thinking..." message
        app.title("BetterText - AI is thinking...")
        
        response = ollama.chat(model='gemma3:4b', messages=[
            {'role': 'system', 'content': 'You are a text processor. Never explain, never add commentary. Output only the final text.'},
            {'role': 'user', 'content': prompt},
        ])
        
        ai_result = response['message']['content'].strip()
        
        # Update text area
        text_area.delete(1.0, tk.END)
        text_area.insert(tk.END, ai_result)
        app.title("BetterText - AI Task Complete")
        
    except Exception as e:
        messagebox.showerror("AI Error", f"Ollama Error: {str(e)}\nMake sure Ollama app is running!")

# --- FILE FUNCTIONS ---

def save_file():
    file_path = filedialog.asksaveasfilename(
        defaultextension=".txt",
        filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")]
    )
    if file_path:
        try:
            content = text_area.get(1.0, tk.END)
            with open(file_path, "w", encoding="utf-8") as file:
                file.write(content)
            messagebox.showinfo("Success", "File saved successfully!")
            app.title(f"BetterText - {file_path}")
        except Exception as e:
            messagebox.showerror("Error", f"Could not save file: {e}")

def open_file():
    file_path = filedialog.askopenfilename(
        title="Select a file",
        filetypes=[("Text Files", "*.txt"), ("All Files", "*.*")]
    )
    if file_path:
        try:
            with open(file_path, "r", encoding="utf-8") as file:
                content = file.read()
            text_area.delete(1.0, tk.END)
            text_area.insert(tk.END, content)
            app.title(f"BetterText - {file_path}")
        except Exception as e:
            error_id = sum([random.randint(567, 876) for _ in range(4)])
            messagebox.showerror("Error", f"Error ID: {error_id}\nCheck error_log.txt")
            with open("error_log.txt", "a") as f:
                f.write(f"\nID: {error_id} | {datetime.now()} | {str(e)}")

# --- MAIN WINDOW ---

app = tk.Tk()
app.title("BetterText")
app.geometry("800x600")

menubar = tk.Menu(app)

# File Menu
file_menu = tk.Menu(menubar, tearoff=0)
file_menu.add_command(label="Open", command=open_file)
file_menu.add_command(label="Save As", command=save_file)
file_menu.add_separator()
file_menu.add_command(label="Exit", command=app.destroy)
menubar.add_cascade(label="File", menu=file_menu)

# Edit Menu
edit_menu = tk.Menu(menubar, tearoff=0)
edit_menu.add_command(label="Undo", command=lambda: text_area.event_generate("<<Undo>>"))
edit_menu.add_command(label="Redo", command=lambda: text_area.event_generate("<<Redo>>"))
menubar.add_cascade(label="Edit", menu=edit_menu)

# AI Enhance Menu
enhance_menu = tk.Menu(menubar, tearoff=0)
enhance_menu.add_command(label="Extend Text", command=lambda: ai_enhance("extend"))
enhance_menu.add_command(label="Shorten Text", command=lambda: ai_enhance("shorten"))
enhance_menu.add_command(label="Fix Grammar", command=lambda: ai_enhance("grammar"))
menubar.add_cascade(label="Enhance", menu=enhance_menu)

# About Menu
about_menu = tk.Menu(menubar, tearoff=0)
about_menu.add_command(label="About", command=lambda: messagebox.showinfo("About", "Made by Skeptical, Do not distribute"))
app.config(menu=menubar)

# --- TEXT AREA ---
text_frame = tk.Frame(app)
text_frame.pack(expand=True, fill="both")

scrollbar = tk.Scrollbar(text_frame)
scrollbar.pack(side="right", fill="y")

text_area = tk.Text(text_frame, wrap="word", undo=True, yscrollcommand=scrollbar.set)
text_area.pack(expand=True, fill="both")

scrollbar.config(command=text_area.yview)

# --- RUN APP ---
app.mainloop()
