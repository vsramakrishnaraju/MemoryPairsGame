//
//  ViewController.swift
//  FinalProject
//
//  Created by Venkata on 3/12/24.
//

import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var images: [UIImage?] = []
    var imageNames: [String?] = []
    var selectedIndices: [IndexPath] = []
    var matchedIndices: [IndexPath] = []
    
    let masterDictionary: [String: [String]] = [
        "Fruits": ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew", "Kiwi", "Lemon", "Mango", "Nectarine", "Orange", "Papaya", "Quince", "Raspberry", "Strawberry", "Tangerine", "Ugli fruit", "Watermelon"],
        "Vehicles": ["Car", "Bus", "Truck", "Bicycle", "Motorcycle", "Airplane", "Helicopter", "Boat", "Scooter", "Train"],
        "Countries": ["India", "USA", "China", "Japan", "Germany", "France", "Italy", "Canada", "Brazil", "Australia"],
        "Objects": ["Clock", "Chair", "Table", "Lamp", "Computer", "Book", "Pen", "Phone", "Camera", "Television"],
        "Colors": ["Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Black", "White", "Pink", "Gray"],
        "Shapes": ["Circle", "Square", "Triangle", "Rectangle", "Diamond", "Heart", "Star", "Oval", "Pentagon", "Hexagon"],
        "Sports": ["Cricket", "Soccer", "Basketball", "Tennis", "Badminton", "Golf", "Baseball", "Volleyball", "Rugby", "Hockey"],
        "Programming": ["Swift", "Objective-C", "Java", "Kotlin", "Python", "JavaScript", "C#", "Ruby", "PHP", "C++"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Match Pairs"
        prepareImageSet()
    }
    
    func prepareImageSet() {
        let allKeys = Array(masterDictionary.keys)
        
        let numberOfRandomSelections = allKeys.count
        
        let randomKeys = (0..<numberOfRandomSelections).map { _ -> String in
            allKeys[Int.random(in: allKeys.indices)]
        }
        
        let randomValues = randomKeys.compactMap { key -> String? in
            masterDictionary[key]?.randomElement()
        }
        
        let combinedSelection = randomKeys + randomValues
        
        let finalresult = combinedSelection.shuffled()
        
        finalresult.forEach { textData in
            let image = drawRectangle(withText: textData)
            ImageManager.shared.saveImage(image, withName: textData)
            images.append(image)
            imageNames.append(textData)
        }
    }
    
    func drawRectangle(withText textData: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 120))
        
        return renderer.image { ctx in
            let rectangle = CGRect(x: 0, y: 0, width: 200, height: 120)
            ctx.cgContext.setFillColor(UIColor.lightGray.cgColor)
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fill)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = textData.size(withAttributes: attributes)
            let textRect = CGRect(x: (rectangle.width - textSize.width) / 2,
                                  y: (rectangle.height - textSize.height) / 2,
                                  width: textSize.width,
                                  height: textSize.height)
            textData.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CustomCollectionViewCell else {
            fatalError("Unable to dequeue CustomCollectionViewCell")
        }
        cell.configure(with: images[indexPath.row], isHidden: selectedIndices.contains(indexPath) || matchedIndices.contains(indexPath))
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if matchedIndices.contains(indexPath) || selectedIndices.count >= 2 {
            return
        }
        
        selectedIndices.append(indexPath)
        
        if selectedIndices.count == 2 {
            attemptMatchBetween(selectedIndices[0], and: selectedIndices[1])
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    func attemptMatchBetween(_ firstIndex: IndexPath, and secondIndex: IndexPath) {
        guard let firstImageName = imageNames[firstIndex.row], let secondImageName = imageNames[secondIndex.row],
              matchedPairs(firstImageName, secondImageName) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.handleMismatchFor([firstIndex, secondIndex])
            }
            return
        }
        
        handleMatchFor([firstIndex, secondIndex])
    }
    
    func handleMismatchFor(_ indices: [IndexPath]) {
        selectedIndices.removeAll()
        collectionView.reloadItems(at: indices)
    }
    
    func handleMatchFor(_ indices: [IndexPath]) {
        matchedIndices.append(contentsOf: indices)
        selectedIndices.removeAll()
        collectionView.reloadItems(at: indices)
        
        if matchedIndices.count == images.count {
            // All pairs are matched, show a win alert
            showWinAlert()
        }
    }
    
    func showWinAlert() {
        let alert = UIAlertController(title: "Congratulations!", message: "You've matched all pairs!", preferredStyle: .alert)
        
        let restartAction = UIAlertAction(title: "Restart", style: .default) { [weak self] _ in
            self?.restartGame()
        }
        alert.addAction(restartAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func restartGame() {
        images.removeAll()
        imageNames.removeAll()
        selectedIndices.removeAll()
        matchedIndices.removeAll()
        
        prepareImageSet()
        
        collectionView.reloadData()
    }
    
    func matchedPairs(_ t1: String?, _ t2: String?) -> Bool {
        guard let t1 = t1, let t2 = t2 else { return false }
        for (key, val) in masterDictionary {
            if (key == t1 && val.contains(t2)) || (key == t2 && val.contains(t1)) {
                return true
            }
        }
        return false
    }
}

struct ImageManager {
    static let shared = ImageManager()
    
    func saveImage(_ image: UIImage, withName name: String) {
        guard let imageData = image.jpegData(compressionQuality: 1),
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(name).jpg")
        try? imageData.write(to: fileURL, options: .atomic)
    }
    
    func loadImage(withName name: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let sanitizedTextData = name.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: " ", with: "_")
        let fileURL = documentsDirectory.appendingPathComponent("\(sanitizedTextData).jpg")
        return UIImage(contentsOfFile: fileURL.path)
    }
}
