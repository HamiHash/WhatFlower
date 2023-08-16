//
//  ViewController.swift
//  WhatFlower
//
//  Created by Hamed Hashemi on 8/14/23.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var textDescription: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
    }
    
    func detect(image: CIImage) {
        
        guard let mlModel = try? FlowerClassifier(configuration: .init()).model, let model = try? VNCoreMLModel(for: mlModel) else {
            fatalError("loading core ml model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            
            // process image and down cast its type
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("model failed to process image, failed to downcast results")
            }
            
            // setting the flower name
            guard let flowerName = results.first?.identifier else {
                fatalError("cant get flower name")
            }
            self.navigationItem.title = flowerName.capitalized
            
            // sending api request wirh Alamofire
            let parameters : [String:String] = [
                "format" : "json",
                "action" : "query",
                "prop" : "extracts|pageimages",
                "exintro" : "",
                "explaintext" : "",
                "titles" : flowerName,
                "indexpageids" : "",
                "redirects" : "1",
                "pithumbsize" : "500"
            ]
            
            AF.request("https://en.wikipedia.org/w/api.php", parameters: parameters,  encoder: URLEncodedFormParameterEncoder.default).responseJSON { response in
                switch response.result {
                case .success(let value):
                    // You can further process the JSON using SwiftyJSON, Codable, or other methods.
                    let FlowerJSON : JSON = JSON(value)
                    print(FlowerJSON)
                    let pageId = FlowerJSON["query"]["pageids"][0].stringValue // getting the pageid to be able to access description in Json
                    let description = FlowerJSON["query"]["pages"][pageId]["extract"].stringValue
                    let imageString = FlowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                    // Setting the description
                    self.textDescription.text = description
                    // Setting the image asynchronously
                    self.setImage(with: imageString)
                    
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
        
        // performing the request
        do {
            try VNImageRequestHandler(ciImage: image).perform([request])
        } catch {
            print("error in performing request \(error)")
        }
    }
    
    // method to get the image from url and set it to image picker
    func setImage(with url : String) {
        
        // if there is an image: (api respond with a flower)
        if let imageURL = URL(string: url) {
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: imageURL) else {
                    fatalError("error while converting image 'URL' to type 'Data' ")
                }
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("could't convert type to ciimage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true)
    }
    
}
