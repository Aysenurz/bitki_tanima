<<<<<<< HEAD
Bitki Tanıma Mobil Uygulaması
Bu proje, kameranızla çektiğiniz veya galerinizden seçtiğiniz bir bitkinin fotoğrafını kullanarak türünü, ailesini ve bakım önerilerini öğrenmenizi sağlayan bir mobil uygulamadır.

Özellikler
Bitki Tanıma: Kamera veya galeriden yüklenen fotoğrafları analiz ederek bitkiyi tanır.

Detaylı Bilgiler: Tanımlanan bitkinin bilimsel adını, ailesini, genel tanımını ve bakım ipuçlarını sunar.

Favorilere Ekleme: Tanıdığınız bitkileri favorilerinize ekleyerek daha sonra kolayca erişebilirsiniz.

Çoklu Dil Desteği: Uygulama arayüzü ve içerik, Türkçe ve İngilizce dillerinde kullanılabilir.

Kimlik Doğrulama: Kullanıcı oturum açma ve çıkış yapma işlemleri Firebase Authentication ile güvenli bir şekilde yönetilir.

Kullanılan Teknolojiler
Flutter: Mobil uygulama geliştirme için ana çerçeve.

Firebase:

Firestore: Bitki verilerini ve kullanıcı favorilerini gerçek zamanlı olarak depolamak için kullanılır.

Authentication: Kullanıcı oturum yönetimini sağlar.

image_picker: Cihazın kamerasından ve galerisinden görüntü seçmek için kullanılır.

flutter_dotenv: Hassas bilgileri (API anahtarları gibi) .env dosyalarıyla güvenli bir şekilde yönetmek için kullanılır.

Kurulum ve Çalıştırma
Bu projeyi yerel ortamınızda çalıştırabilmek için aşağıdaki adımları takip edin.

Ön Gereksinimler
Flutter SDK (v3.13.0 veya üstü önerilir)

Firebase CLI

Adımlar
Projeyi klonlayın:

git clone [https://github.com/kullanici-adiniz/bitki_tanima_mobile.git](https://github.com/kullanici-adiniz/bitki_tanima_mobile.git)
cd bitki_tanima_mobile

Bağımlılıkları yükleyin:

flutter pub get

Firebase'i yapılandırın:

Firebase projenizi oluşturun.

Aşağıdaki komutu çalıştırarak Firebase CLI'yi projenize bağlayın:

flutterfire configure

lib/firebase_options.dart dosyasının başarıyla oluşturulduğunu doğrulayın.

Uygulamayı çalıştırın:

flutter run

Ekran Görüntüleri
[Uygulamanın ana sayfası, bitki tanıma ekranı ve detay sayfası gibi ekran görüntülerine bu bölümde yer verin.]
=======
# bitki_tanima_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> a1356e7c0c904980dfe566ba55b797e08e83b8af
