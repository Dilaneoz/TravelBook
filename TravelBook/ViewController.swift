//
//  ViewController.swift
//  TravelBook
//
//  Created by Atil Samancioglu on 27.07.2019.
//  Copyright © 2019 Atil Samancioglu. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

// entity coredata sınıfı viewmodel imizdir. bu modelin içinde olmasını istediğimiz attributeları yazıyoruz. entity xcode da bi bölüm. neleri coredataya kaydediceksek onları ekleriz

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate { // bu class ları eklemenin sebebi bu classlardaki fonksiyonları kullanabilmek

    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager() // kullanıcının konumunu alıcaksam, kullanıcının konumuyla ilgili işlemler yapıcaksam ya da bunu kendi haritamda vs göstericeksem bu class ı kullanıyoruz. bu tip işlemlerde genelde manager yazar
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self // locationManager ın delegate ının bu viewcontroller olduğu söylüyoruz
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // konumun verisi ne kadar keskinlikle bulunacak onu belirtiyoruz. kCLLocationAccuracyBest bu en keskin olan ama pili en çok yiyen bu. yemesin istiyosak sonu kilometer olanı seçebiliriz. ama bu bi kilometreye kadar sapmalı verir
        locationManager.requestWhenInUseAuthorization() // kullanıcıdan api kullanırken izin isteme
        locationManager.startUpdatingLocation() // kullanıcının yerini almaya başlıyoruz. bunu yaptıktan sonra infoplist e gidip ekleme yapmak gerek
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:))) // uzun basınca çağır
        gestureRecognizer.minimumPressDuration = 3 // 3 sn basarsa pini aktive et
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" { // title boş değilse coredata dan çekmeye çalışıcaz
            //CoreData
          
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String { // title verildiyse subtitle ı da kontrol et
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double { // subtitle verildiyse latitude ı da kontrol et
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double { // latitude verildiyse longitude ı da kontrol et
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation() // kullanıcı konum değiştirdiğinde kaydedilmiş lokasyonlardaki controller a girildiğinde harita konumu güncellenmemesi için stopUpdatingLocation i kullanıyoruz yani konumu güncellemeyi durduruyoruz
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span) // kaydedilmiş konumu ver
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
             
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
            
            
        } else { // boşsa burda saklamaya gerek yok
            //Add New Data
        }
        
        
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began { // gestureRecognizer başladıysa
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // dokunulan noktayı alabilmek için
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) // dokunulan noktayı koordinata çevir
            
            chosenLatitude = touchedCoordinates.latitude // kullanıcı her dokunduğunda buradaki değerler değişecek ve save fonksiyonuna gidip kaydedicez
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation() // pini oluştur
            annotation.coordinate = touchedCoordinates // dokunulan yer koordinatımız
            annotation.title = nameText.text // kullanıcı nameText te ne yazdıysa onu geçir
            annotation.subtitle = commentText.text  // pine altyazı ekliyoruz. kullanıcı yorum satırına ne yazdıysa o
            self.mapView.addAnnotation(annotation) // pini ekle
            
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // bu fonksiyon güncellenen konumları bir dizi içerisinde veriyor. CLLocation objesi içinde enlem ve boylam barındıran bir obje
        
        if selectedTitle == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // kullanıcı nerdeyse(coordinate) bi lokasyon oluştur, enlem ve boylamını ayarla
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // o lokasyona bu kadar zumla
        let region = MKCoordinateRegion(center: location, span: span) // nereyi merkez alıyım ve ne kadar zumlıyım
        mapView.setRegion(region, animated: true)
        } else { // kaydedilmiş konum bazen hatalı gözükebiliyor. else dersek kaydedilen konum dışında bir konum göstermemesini kesinleştiriyoruz
            //
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? { // pin i özelleştirmek için
        
        if annotation is MKUserLocation { // kullanıcının yerini pinle göstermek istemiyorum
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil { // pinView daha oluşturulmadıysa
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // özelleştirmeye başladık. bu i yazan baloncukla ek bilgi gösteririrz
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure) // baloncuğun içinde detay göstermek için bir buton oluşturcak
            pinView?.rightCalloutAccessoryView = button // sağ tarafta göster
            
        } else {
            pinView?.annotation = annotation
        }
        
        
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) { // oraya tıklandıysa ne olacak
        
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            //closure
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in // koordinatlar ve yerler arasında bağlantı kurmaya yarar. requestLocation gitmek istenilen yer. reverseGeocodeLocation navigasyonumu çalıştırmak için gerekli olan objeyi almak için kullanılır. ya placemarks dizisini ver ya da hata. çünkü o dizinin içinde bulunan placemarks ı alarak başlayabiliyoruz. placemark denilen objeyi reverseGeocodeLocation ile alıyoruz
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                                      
                        let newPlacemark = MKPlacemark(placemark: placemark[0]) // placemarks içinden 0 ı al. mapItem ı açabilmek için placemark denilen obje gerekli
                        let item = MKMapItem(placemark: newPlacemark) // navigasyonu açabilmek için bir mapItem oluşturmak gerekiyo
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving] // bu dictionary nasıl bir navigasyon yapıcağımızı yazıyoruz. hangi araçla göstericez. göstericeğim araç araba olsun
                        item.openInMaps(launchOptions: launchOptions)
                }
            }
        }
        }
    }
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context) // kullanıcının kaydetmek istediği verileri koyacağı yer
        
        newPlace.setValue(nameText.text, forKey: "title") // istediğim anahtar kelimeye karşılık istediğim değerleri kaydedebiliyorum
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id") // istediğim değerleri kaydettim
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil) // bütün app e bir mesaj yolluyor. diğer tarafta bir observer kullanarak bu newPlace mesajı gelince ne yapacağımızı söyleyebiliyoruz
        navigationController?.popViewController(animated: true) // bi önceki controller a geri götür
        
        
    }
    
    
    
}

