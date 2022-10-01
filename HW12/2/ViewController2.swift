import UIKit
import CoreML
import Vision


class ViewController2: UIViewController {
    
    @IBOutlet weak var catsImages: UIImageView!
    @IBOutlet weak var catsDetection: UILabel!
    
    @IBOutlet weak var dogsImages: UIImageView!
    @IBOutlet weak var dogsDetection: UILabel!
    
    @IBOutlet weak var miceImages: UIImageView!
    @IBOutlet weak var miceDetection: UILabel!
    
    @IBOutlet weak var treeImages: UIImageView!
    @IBOutlet weak var treeDetection: UILabel!
    
    let delay: TimeInterval = 5.0
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.serialVisionQueue")
    
    func test(imageView: UIImageView, outputInfo: UILabel, detect: String) {
        let classificationRequest: VNCoreMLRequest = {
            do {
                let model = try VNCoreMLModel(for: SkillboxClassifier().model)
                
                let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                    self?.processClassifications(for: request, error: error, outputInfo: outputInfo, identifier: detect)
                })

                let value: Int = imageView.contentMode.rawValue
                switch value {
                case 0:
                  
                    request.imageCropAndScaleOption = .centerCrop
                case 1:
                   
                    request.imageCropAndScaleOption = .scaleFit
                case 2:
                    
                    request.imageCropAndScaleOption = .scaleFill
                default:
                   
                    request.imageCropAndScaleOption = .centerCrop
                }
                return request
            } catch {
                fatalError("Ошибка загрузки ML модели: \(error)")
            }
        }()
        
        func updateClassifications(_ image: UIImage) {
            outputInfo.text = "Анализирую..."
            
          
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            
            guard let ciImage = CIImage(image: image) else { return print("Невозможно создать \(CIImage.self) из \(image).")}
            
            visionQueue.async {
                let handler = VNImageRequestHandler(ciImage: ciImage,
                                                    orientation: orientation)
                do {
                    try handler.perform([classificationRequest])
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        updateClassifications(imageView.image!)
    }
    
    func processClassifications(for request: VNRequest, error: Error?, outputInfo: UILabel?, identifier: String) {
        
        guard let results = request.results else {
            print("Ошибка анализа: \(error!.localizedDescription)")
            return
        }
        
        if results.isEmpty {
            print("results.isEmpty")
        } else if let observations = request.results as? [VNClassificationObservation] {
            
        
            let topResults = observations.prefix(3)
            
            let descriptions = topResults.map { results in
                return String(format: "%@: %.0f", results.confidence * 100, results.identifier) + "%"
            }
            

            let best = observations.first
            let bestPrefix = best!.identifier.hasPrefix(identifier)
            let bestConfidence = best!.confidence
            
            DispatchQueue.main.async {
                if bestPrefix && bestConfidence >= 0.9 {
                    outputInfo?.backgroundColor = .systemGreen
                } else if bestPrefix && bestConfidence >= 0.6 {
                    outputInfo?.backgroundColor = .systemYellow
                } else {
                    outputInfo?.backgroundColor = .systemRed
                }
                outputInfo?.text = "Результат:\n" + descriptions.joined(separator: "\n")
            }
        }
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let alert = UIAlertController(title: "Внимание!", message: "После нажатия \"ОК\" каждые 5 секунд начнется загрузка и классификация изображений", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: { action in
            
            Timer.scheduledTimer(timeInterval: self.delay, target: self, selector: #selector(self.catTimer), userInfo: nil, repeats: true)
            
            Timer.scheduledTimer(timeInterval: self.delay, target: self, selector: #selector(self.dogsTimer), userInfo: nil, repeats: true)
            
            Timer.scheduledTimer(timeInterval: self.delay, target: self, selector: #selector(self.micesTimer), userInfo: nil, repeats: true)
            
            Timer.scheduledTimer(timeInterval: self.delay, target: self, selector: #selector(self.treesTimer), userInfo: nil, repeats: true)
            
            var sec = 5
            while sec > 0 {
                print("Старт через \(sec) сек")
                sec -= 1
                sleep(1)
            }
        }))
        
        self.present(alert, animated: true)
    }
    
    
    @objc func catTimer() {
      
        let n = Int.random(in: 400...500)
        let url = URL(string: "https://placekitten.com/\(n)/\(n)")!
        
        if let data = try? Data(contentsOf: url) {
            let img = UIImage(data: data)
            DispatchQueue.main.async {
                self.catsImages.image = img
                self.test(imageView: self.catsImages, outputInfo: self.catsDetection, detect: "cat")
            }
        }
    }
    
    @objc func dogsTimer() {
      
        guard let test = URL(string: "https://dog.ceo/api/breeds/image/random") else { return }
        let task = URLSession.shared.dataTask(with: test) { (data, response, error) in
            guard let response = data, error == nil else {
                print(error?.localizedDescription ?? "ошибка response"); return }
            do {
                let json = try JSONSerialization.jsonObject(with: response, options: []);
                
                guard let jsonArr = json as? [String:String] else { return };
                guard let message = jsonArr["message"] else { return }
            
                
                let url = URL(string: message)!
                
                if let data = try? Data(contentsOf: url) {
                    let img = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.dogsImages.image = img
                        self.test(imageView: self.dogsImages, outputInfo: self.dogsDetection, detect: "dog")
                    }
                }
                
            } catch let parsingError { print("Error", parsingError) }
        }
        task.resume()
    }
    

    @objc func micesTimer() {
      
        guard let test = URL(string: "https://pixabay.com/api/?key=17295923-36a07c48c0a45e440093964e7&q=mices&image_type=photo&pretty=true&page=\(Int.random(in: 1...10))") else { return }
        
        let task = URLSession.shared.dataTask(with: test) { (data, response, error) in
            guard let response = data, error == nil else {
                print(error?.localizedDescription ?? "ошибка response"); return }
            do {
                let json = try JSONSerialization.jsonObject(with: response, options: []);
                
                guard let jsonDict = json as? NSDictionary else { return };
                
                guard let URLs = jsonDict["hits"] as? [[String:Any]] else { return }
                
                var links: [String] = []
                
                for url in URLs {
                    links.append(url["webformatURL"] as! String)
                }
                
                let url = URL(string: links.randomElement()!)!
                
                if let data = try? Data(contentsOf: url) {
                    let img = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.miceImages.image = img
                        self.test(imageView: self.miceImages, outputInfo: self.miceDetection, detect: "mice")
                    }
                }
                
            } catch let parsingError {
                print("Error", parsingError)
            }
        }
        task.resume()
    }
    

    @objc func treesTimer() {
      
        guard let test = URL(string: "https://pixabay.com/api/?key=17298086-cd25ee4c9ebe1644d81ca317e&q=trees&image_type=photo&pretty=true&page=\(Int.random(in: 1...10))") else { return }
        
        let task = URLSession.shared.dataTask(with: test) { (data, response, error) in
            guard let response = data, error == nil else {
                print(error?.localizedDescription ?? "ошибка response"); return }
            do {
                let json = try JSONSerialization.jsonObject(with: response, options: []);
                
                guard let jsonDict = json as? NSDictionary else { return };
                
                guard let URLs = jsonDict["hits"] as? [[String:Any]] else { return }
                
                var links: [String] = []
                
                for url in URLs {
                    links.append(url["webformatURL"] as! String)
                }
                
                let url = URL(string: links.randomElement()!)!
                
                if let data = try? Data(contentsOf: url) {
                    let img = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.treeImages.image = img
                        self.test(imageView: self.treeImages, outputInfo: self.treeDetection, detect: "tree")
                    }
                }
            } catch let parsingError { print("Error", parsingError) }
        }
        task.resume()
    }
}
