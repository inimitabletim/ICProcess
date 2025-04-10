//
//  PubFunction.swift
//  DOEPlatform
//
//  Created by Chad Hsu on 2024/8/20.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import PhotosUI

//MARK: DSPoint
struct DSPoint: Codable {
    var x: Int32
    var y: Int32
}

//MARK: Extensions
extension Image {
    func topBarImageStyle() -> some View {
        self.font(.largeTitle)
            .foregroundColor(.white)
            .shadow(color: .red, radius: 2, x: 2, y: 2)
            .frame(width: 50)
    }
}

extension Text {
    func topBarTextStyle() -> some View {
        self.font(.custom("Avenir Next Condensed", size: 28))
            .foregroundColor(.white)
            .truncationMode(.head)
            .shadow(color: .red, radius: 2, x: 2, y: 2)
            .lineLimit(2)
            .lineSpacing(0)
    }
    func menuBlockTextStyle(width: CGFloat) -> some View {
        self.font(.system(size: width))
            .foregroundColor(.gray)
            .frame(minWidth: width * 10)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 2)
                    .fill(Color.orange)
            )
            .buttonStyle(PlainButtonStyle())
            .padding()
    }
    func menuLabelStyle(width: CGFloat, fill: Bool = false, color: Color = .orange, align: Alignment = .leading) -> some View {
        self.fontWeight(.bold)
            .foregroundColor(fill ? Color.gray : color)
            .padding(5)
            .frame(width: width, alignment: align)
            .background(fill ? Color.yellow.opacity(0.3) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(lineWidth: 1)
                    .foregroundColor(color)
            )
    }
    func selectDef(result: Bool, textcolor: Color = .gray) -> some View {
        self.fontWeight(result ? .bold: .none)
            .foregroundColor(result ? .white: textcolor)
            .frame(maxWidth: 300)
            .background(result ? Color.orange.opacity(0.85): Color.white.opacity(0))
            .cornerRadius(result ? 10: 0)
            .padding()
    }
}

extension HStack {
    func topBarBackgroundStyle() -> some View {
        self.padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow, Color.orange]), startPoint: .leading, endPoint: .trailing))
    }
    func buttonSwitchStyle(selectIndex: Int, buttonIndex: Int, members: CGFloat, buttonColor: Color? = nil) -> some View {
        self.frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width / members, minHeight: 0, maxHeight: 20)
            .padding(5)
            .foregroundColor(selectIndex == buttonIndex ? .white : (buttonColor ?? .orange))
            .background(selectIndex != buttonIndex ? Color.white : (buttonColor ?? Color.orange).opacity(0.85))
            .cornerRadius(40)
            .overlay(
                RoundedRectangle(cornerRadius: 40).stroke(buttonColor ?? Color.orange, lineWidth: 1)
            )
            .padding(buttonIndex == 0 ? .leading : .trailing)
    }
}

extension TextEditor {
    func bottomLineOrange() -> some View{
        self.padding(.vertical, 10)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.orange),
            alignment: .bottom
        )
        .padding(.horizontal, 10)
    }
}

extension TextField {
    func fillStyle(_ fill: Bool = true) -> some View {
        self.padding(5)
            .background(fill ? Color.yellow.opacity(0.3) : Color.white)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
    
    func bottomLineOrange() -> some View{
        self.padding(.vertical, 10)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.orange),
            alignment: .bottom
        )
        .padding(.horizontal, 10)
    }
    
}

extension String {
    func length() -> Int {
        return (self as NSString).length
    }
    var isDigit: Bool {
        return CharacterSet.decimalDigits.contains(self.unicodeScalars.first!)
    }
    var removeAllSapce: String {
        return self.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
    }
    
    func removeExtension(_ ext: String) -> String {
        guard self.lowercased().hasSuffix(ext.lowercased()) else { return self }
        return String(self.dropLast(ext.count))
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
    // Split an array into chunks
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

}


extension UTType {
    static var inc: UTType {
        UTType.types(tag: "inc", tagClass:.filenameExtension, conformingTo: UTType.data)[0]
    }
    static var lib: UTType {
        UTType.types(tag: "lib", tagClass: .filenameExtension, conformingTo: UTType.data).first!
    }
    static var l : UTType{
        UTType.types(tag: "l", tagClass: .filenameExtension, conformingTo: UTType.data).first!
    }
    static var netlist : UTType{
        UTType.types(tag: "netlist", tagClass: .filenameExtension, conformingTo: UTType.data).first!

    }
    static var cdl : UTType{
        UTType.types(tag: "cdl", tagClass: .filenameExtension, conformingTo: UTType.data).first!

    }
    static var numbers : UTType{
        UTType.types(tag: "numbers", tagClass: .filenameExtension, conformingTo: UTType.data).first!

    }
    static var csv : UTType{
        UTType.types(tag: "csv", tagClass: .filenameExtension, conformingTo: UTType.data).first!

    }
}

//MARK: Search Bar
struct SearchBar: View {
    
    @Binding var text: String
    @State private var isEditing = false
    var remind = "Search ..."
    var body: some View {
        HStack {
            TextField(remind, text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if isEditing {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isEditing = true
                }
            
            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    
                    // Dismiss the keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
            }
        }
    }
}


struct SearchHistoryRow: View {
    let term: String
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text(term)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

//MARK: Alert
struct alertInfo: Identifiable {
    enum alertType {
        case finish
        case error
        case empty
        case exist
        case warning
    }
    
    let id: alertType
    let title: String
    let message: String
}

//MARK: Special Character
func containsSpecialCharacters(string: String, isNum: Bool = false) -> Bool {
    // isNum: For Number only
    do {
        let charPattern = isNum ? "[^0-9]" : "[^a-z0-9]"
        let regex = try NSRegularExpression(pattern: charPattern, options: .caseInsensitive)
        if let _ = regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) {
            return true
        } else {
            return false
        }
    } catch {
        debugPrint(error.localizedDescription)
        return true
    }
}
func removeSpecialCharacters(from input: String) -> String {
    let allowedCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789")
    return String(input.filter { allowedCharacters.contains($0) })
}

//MARK: Copy Coredata
// Copy all attributes of an entity
func copyAttributes(from object: NSManagedObject) -> NSManagedObject? {
    let context = object.managedObjectContext
    let entity = object.entity
    let copiedObject = NSManagedObject(entity: entity, insertInto: context)
    for attribute in entity.attributesByName {
        let attributeName = attribute.key
        copiedObject.setValue(object.value(forKey: attributeName), forKey: attributeName)
    }
    return copiedObject
}

//MARK: LazyView
public struct LazyView<veryLazy: View>: View {

    private let build: () -> veryLazy
    public init(_ build: @autoclosure @escaping () -> veryLazy) {
        self.build = build
    }
    public var body: veryLazy {
        build()
    }
}

//class DOEMatrixEditor: NSObject {
//    
//    // Calculate Value which References to other Parameter
//    func calculateParaValue(orgValue: String, defPara: [String:String]) -> String {
//        var newValue = orgValue
//        // Separate Value into Array ("a+2.5+b" -> ["a", "+", "2.5", "+", "b"])
//        var valArray = EquationStringToArray(inEquation: newValue).equationSplitor()
//        while valArray.contains(where: { defPara[$0] != nil }) {
//            // Replace default parameter Name to default parameter Value
//            for i in valArray.indices {
//                while defPara[valArray[i]] != nil {
//                    valArray[i] = defPara[valArray[i]]!
//                }
//            }
//            valArray = EquationStringToArray(inEquation: valArray.joined()).equationSplitor()
//        }
//        newValue = valArray.joined()
//        
//        if Double(newValue) != nil {
//            return newValue
//        }
//        let calculatedValue = EquationCalculator(inEquation: newValue).calculate()
//        return calculatedValue == -999 ? orgValue : String(format: "%g", calculatedValue)
//    }
//    
//    // Simplfy Dictionary if it has fomula, and check if Value reference to its Own key
//    func dictionaryChecker(dict: [String: String]) -> (newDictionary: [String: String], errorList: [String]) {
//        var newDict = dict
//        var errList: [String] = []
//        for (key, val) in dict {
//            var valArr = EquationStringToArray(inEquation: val).equationSplitor()
//            while valArr.contains(where: { newDict[$0] != nil }) {
//                // Append Key to errList if the value References to Key
//                if valArr.contains(key) {
//                    errList.append(key)
//                    break
//                }
//                // Update value
//                for i in valArr.indices {
//                    while newDict[valArr[i]] != nil {
//                        valArr[i] = newDict[valArr[i]]!
//                    }
//                }
//                valArr = EquationStringToArray(inEquation: valArr.joined()).equationSplitor()
//            }
//            let calculatedValue = EquationCalculator(inEquation: valArr.joined()).calculate()
//            newDict[key] = calculatedValue == -999 ? valArr.joined() : String(format: "%g", calculatedValue)
//        }
//        return (newDict, errList)
//    }
//    
//    
//    func fetchDefaultValues(doePlan: DOEPlan?, colTitles: [String]) -> [String: String] {
//        var defVal: [String: String] = [:]
//        let doeTestkeyDesignPara = doePlan?.doeTestkeyDesignParas?.first(where: { ($0 as AnyObject).designParaType == 100 }) as! DOETestkeyDesignPara
//        for doeTestkeyParaValue in doeTestkeyDesignPara.doeTestkeyParaValues! {
//            let dtpv = doeTestkeyParaValue as! DOETestkeyParaValue
////            let designParameter = dtpv.designParaValue?.designParameter
////            if designParameter != nil {
////                let mdParaName = designParameter!.mdParameter!.mdParameterName!
////                if !colTitles.contains(mdParaName) {
////                    defVal[mdParaName] = designParameter!.defaultValue
////                }
////            }
//        }
//        return dictionaryChecker(dict: defVal).newDictionary
//    }
//    
//    // Transform default value dictionary into Matrix with reference to the Value of each Rows
//    func defaultValueToMatrix(colTitles: [String], valueMatrix: [[String]], defVal: [String: String]) -> [[String]] {
//        var defaultMatrix: [[String]] = []
//        for valueArray in valueMatrix {
//            // Update value to dictionary from current row
//            var tmpDef = defVal
//            for i in valueArray.indices {
//                tmpDef[colTitles[i]] = valueArray[i]
//            }
//            // Calculate value of temp dictionary
//            tmpDef = DOEMatrixEditor().dictionaryChecker(dict: tmpDef).newDictionary
//            var defaultArray: [String] = []
//            for key in tmpDef.keys.sorted(by: <) {
//                if !colTitles.contains(key) {
//                    defaultArray.append(tmpDef[key]!)
//                }
//            }
//            defaultMatrix.append(defaultArray)
//        }
//        return defaultMatrix
//    }
//    
//    // Check if Value reference to its Own key
//    func matrixChecker(matrix: [[String]]) -> [String] {
//        let titleList = matrix.map{$0[0]}
//        var errList: [String] = []
//        for row in matrix.indices {
//            for col in 1 ..< matrix[row].count {
//                var valArr = EquationStringToArray(inEquation: matrix[row][col]).equationSplitor()
//                while titleList.contains(where: { valArr.contains($0) }) {
//                    let rowTitle = matrix[row][0]
//                    if valArr.contains(rowTitle) {
//                        errList.append(rowTitle)
//                        break
//                    }
//                    
//                    for i in valArr.indices {
//                        while titleList.contains(valArr[i]) {
//                            let refRow = matrix.first(where: { $0[0] == valArr[i] })!.dropFirst().joined(separator: "+")
//                            valArr[i] = refRow
//                        }
//                    }
//                    valArr = EquationStringToArray(inEquation: valArr.joined()).equationSplitor()
////                    print(valArr)
//                }
//            }
//        }
//        return errList.removingDuplicates()
//    }
//}

//MARK: For device orientation
class DeviceOrientation: ObservableObject {
    @Published var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .sink { [weak self] newOrientation in
                guard let self = self else { return }
                self.isLandscape = newOrientation.isLandscape
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct CustomCorners: Shape {

    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        return Path(path.cgPath)
    }
}

//MARK: Photo picker
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    guard let self = self else { return }
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

//MARK: For account and password alert
class UIHelper {
    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter {$0.activationState == .foregroundActive}
            .compactMap {$0 as? UIWindowScene}
            .first?.windows.filter {$0.isKeyWindow}.first
    }
    func showAlert(alert: UIAlertController) {
        if let controller = topMostViewController() {
            controller.present(alert, animated: true)
        }
    }
    private func topMostViewController() -> UIViewController? {
        guard let rootController = keyWindow()?.rootViewController else {
            return nil
        }
        return topMostViewController(for: rootController)
    }
    private func topMostViewController(for controller: UIViewController) -> UIViewController {
        if let presentedController = controller.presentedViewController {
            return topMostViewController(for: presentedController)
        } else if let navigationController = controller as? UINavigationController {
            guard let topController = navigationController.topViewController else {
                return navigationController
            }
            return topMostViewController(for: topController)
        } else if let tabController = controller as? UITabBarController {
            guard let topController = tabController.selectedViewController else {
                return tabController
            }
            return topMostViewController(for: topController)
        }
        return controller
    }
}


