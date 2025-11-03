# Askademia 📚

Askademia adalah aplikasi forum online yang dibuat khusus untuk mahasiswa. Di platform ini, mahasiswa dapat berdiskusi, bertanya, dan berbagi informasi seputar perkuliahan, magang, tips skripsi, dan berbagai hal lainnya yang berkaitan dengan kehidupan kampus dan persiapan dunia kerja.

---

## 🎯 Chosen SDG: SDG 4 – Quality Education

Justification: Askademia mendukung tujuan SDG 4 dengan menyediakan platform inklusif dan partisipatif yang memungkinkan mahasiswa berbagi pengetahuan, berdiskusi tentang tantangan akademik, serta saling membantu dalam mencapai keberhasilan pendidikan tinggi.
---

## 🚀 Features

| Category | Feature | Description |
|-----------|----------|-------------|
| **Authentication** | Login & Register | Pengguna dapat membuat akun baru dan login menggunakan email & password. |
| **User Profile** | Profile View | Menampilkan data profil pengguna. |
|  | Edit Profile | Mengubah nama / bio |
| **Post Management** | Create Post | Membuat postingan baru berisi pertanyaan atau opini. |
|  | Edit/Delete Post | Mengubah atau menghapus postingan milik sendiri. |
|  | Post Detail | Menampilkan isi lengkap postingan dan komentar. |
| **Interaction** | Comment / Reply | Memberi tanggapan dan berdiskusi dalam thread komentar. |
| **Feed & Discovery** | Home Feed | Menampilkan daftar postingan terbaru dari seluruh pengguna. |
| **Personalization** | **Bookmark** | Menyimpan postingan favorit agar mudah diakses kembali. |
| **Information Hub** | **Pojok Info** | Menampilkan informasi seputar **magang, webinar, lomba, atau beasiswa** yang sedang berlangsung. |
| **Planned Features (Next Release)** | Follow User, Polling, Chat | Fitur tambahan untuk meningkatkan interaksi dan engagement pengguna. |

---

## 🏗️ Architecture

Aplikasi menggunakan pola **Model–View–Controller (MVC)** untuk memastikan struktur kode yang terorganisir dan mudah dikembangkan.

```
---

## 🛠️ Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/username/askademia.git
   cd askademia
````

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Setup Firebase**

   * Buat project di [Firebase Console](https://console.firebase.google.com/)
   * Tambahkan aplikasi Android & iOS
   * Unduh file `google-services.json` dan simpan di:

     ```
     android/app/
     ```
   * Aktifkan Firebase Authentication, Firestore Database, dan Cloud Messaging.

4. **Run the App**

   ```bash
   flutter run
   ```

## 📱 APK Download Links
| Architecture | Download Link |
|---------------|----------------|
| ARM64 (v8a) | [Download](https://drive.google.com/drive/folders/1d24WY0Ch3GZAWO0uxDWf4KnyxZe-rggA?usp=sharing) |
| ARM32 (v7a) | [Download](https://drive.google.com/drive/folders/1d24WY0Ch3GZAWO0uxDWf4KnyxZe-rggA?usp=sharing) |
| x86_64 | [Download](https://drive.google.com/drive/folders/1d24WY0Ch3GZAWO0uxDWf4KnyxZe-rggA?usp=sharing) |

---

## 🧠 Key Technical Implementations

* **Firebase Authentication** untuk login/register.
* **Firestore Database** untuk menyimpan postingan, komentar, bookmark, dan data info.
* **MVC Pattern** untuk menjaga pemisahan antara UI, logic, dan data.
* **Error Handling & Toast Feedback** agar pengguna mendapat umpan balik yang jelas.

---

> *“Ask, Learn, and Grow Together with Askademia.”*