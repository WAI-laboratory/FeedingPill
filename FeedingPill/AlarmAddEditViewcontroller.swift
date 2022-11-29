import UIKit
import Foundation
import MediaPlayer
import AddThen
import SnapKit
import Combine
import RealmSwift

class AlarmAddEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var subscription = Set<AnyCancellable>()

    let dateFormatter: DateFormatter = {
        let _dateFormatter = DateFormatter()
        _dateFormatter.dateFormat = "hh:mm a"
        return _dateFormatter
    }()
    
    private var imagePicker: UIImagePickerController = .init()
    var imageViewWrapperView = UIView()
    var imageView = UIImageView()
    var plusImageView = UIImageView()
    var selectedImage: UIImage? = nil
    var tableView: UITableView = .init()
    var selectedWeekDays = WeekDaysManager()
    
    var snoozeEnabled: Bool = false
    var pillName: String? = nil {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var suggestedUse: String? = nil {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var pillType: PillType = .nutrients
    
    var selectedWeekDaysObserver: AnyCancellable? = nil
    
    var saveButton: UIBarButtonItem!
    @Published var dates: [Date] = []
    var datesDidchanged: () = Void() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        selectedWeekDaysObserver = self.selectedWeekDays.didChanged$.sink(receiveValue: { [weak self] _ in
            self?.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()

    }
    
    deinit {
        self.selectedWeekDaysObserver?.cancel()
    }
    
    
    private func initView() {
        view.backgroundColor = .systemBackground
        self.saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.save))
        self.saveButton.isEnabled = false
        navigationItem.rightBarButtonItems = [saveButton]
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        view.add(imageViewWrapperView) {
            let interaction = UIContextMenuInteraction(delegate: self)
            $0.addInteraction(interaction)
            
            let tapAction = UITapGestureRecognizer(target: self, action: #selector(self.tapImageView))
            $0.addGestureRecognizer(tapAction)
            $0.add(self.imageView) {
                $0.image = UIImage(named: "pillCombined")
                $0.backgroundColor = .systemGray2
                $0.layer.cornerRadius = 12
                $0.layer.masksToBounds = true
                $0.snp.makeConstraints { make in
                    make.height.width.equalTo(80)
                    make.center.equalToSuperview()
                }

            }
            $0.snp.makeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.trailing.leading.equalToSuperview()
                make.height.equalTo(120)
            }


        }
        self.imageViewWrapperView.add(UIView()) {

            $0.backgroundColor = .systemGray4
            $0.layer.cornerRadius = 16
            $0.layer.masksToBounds = true
            $0.snp.makeConstraints { make in
                make.width.height.equalTo(32)
                make.trailing.equalTo(self.imageView).offset(12)
                make.bottom.equalTo(self.imageView).offset(12)
                
            }
            $0.add(self.plusImageView) {
                $0.image = UIImage(systemName: "camera")
                $0.contentMode = .scaleAspectFit
                $0.tintColor = .tertiaryLabel
                $0.snp.makeConstraints { make in
                    make.width.height.equalTo(24)
                    make.center.equalToSuperview()
                }
            }
        }
        
        
        
        view.add(tableView) {
            $0.delegate = self
            $0.dataSource = self
            $0.register(AlarmTextFieldTableViewCell.self, forCellReuseIdentifier: "AlarmTextFieldTableViewCell")
            $0.register(AlarmNormalTableViewCell.self, forCellReuseIdentifier: "AlarmNormalTableViewCell")
            
            $0.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(self.imageViewWrapperView.snp.bottom)
            }
        }
//
//        dates.publisher
//            .sink { dates in
//                <#code#>
//            }
//            .store(in: &subscription)
        $dates.sink { [weak self] dates in
            if dates.count > 0 {
                self?.saveButton.isEnabled = true
            } else {
                self?.saveButton.isEnabled = false
            }
        }
        .store(in: &subscription)
        
    }
    
    @objc
    func tapImageView() {
        let menu = UIMenu(children: [
            photoLibraryAction,
            cameraAction,
        ])
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoAlert = UIAlertAction(title: "Photo Album", style: .default) { [weak self] _ in
            self?.presentImagePicker()
        }
        
        let cameraAlert = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentCamera()
        }
        
        alertController.addAction(photoAlert)
        alertController.addAction(cameraAlert)
        self.present(alertController, animated: true)
        
    }
    
    private lazy var photoLibraryAction = UIAction(title: "Photo Album", state: .off) { [weak self] _ in
        self?.presentImagePicker()
    }
    private lazy var cameraAction = UIAction(title: "Camera", state: .off) { [weak self] _ in
        self?.presentCamera()
    }
    
    private func presentImagePicker() {
        present(imagePicker, animated: true)
    }
    
    private func presentCamera() {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        } else {
            
        }
    }
 
    func numberOfSections(in tableView: UITableView) -> Int {
            return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        }
        else {
            return dates.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
         return "Information"
        } else {
            return "Time"
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmNormalTableViewCell.identifier)
                cell!.textLabel!.text = "Repeat"
                cell!.detailTextLabel!.text = AlarmAddEditViewController.repeatText(weekdays: self.selectedWeekDays.weekdays)
                return cell!
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmNormalTableViewCell.identifier)
                cell!.textLabel!.text = "Name"
                cell!.detailTextLabel!.text = self.pillName
                return cell!
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmNormalTableViewCell.identifier)
                cell!.textLabel!.text = "Suggested Use"
                cell!.detailTextLabel!.text = self.suggestedUse
                return cell!
                
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmNormalTableViewCell.identifier)
                cell!.textLabel!.text = "Pill Type"
                cell!.detailTextLabel!.text = self.pillType.rawValue
                return cell!
                
            default:
                return UITableViewCell()
                
            }
            
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmNormalTableViewCell.identifier)
                cell?.textLabel?.text = "Add a new time"
                cell?.detailTextLabel?.text = nil
                
                return cell!
                
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: AlarmNormalTableViewCell.identifier)
                cell?.textLabel?.text = "Time \(indexPath.row)"
                let text = self.dateFormatter.string(from: self.dates[indexPath.row - 1])
                cell?.detailTextLabel?.text = text
                
                return cell!
            }
        }
        return UITableViewCell()
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            switch indexPath.row{
            case 0:
                self.present(WeekdaysViewController(weekdays: selectedWeekDays), animated: true)
                cell?.setSelected(true, animated: false)
                cell?.setSelected(false, animated: false)
            case 1:
                
                let alertController = UIAlertController(title: "Supplements Name?", message: nil, preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = "Enter the name."
                }
                
                let alertAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    if let text = alertController.textFields?[0].text {
                        self?.pillName = text
                    }
                }
                
                let cancel = UIAlertAction(title: "cancel", style: .destructive)
                
                alertController.addAction(alertAction)
                alertController.addAction(cancel)
                self.present(alertController, animated: true)
                
            case 2:
                let alertController = UIAlertController(title: "Supplements Quantity?", message: nil, preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = "Enter the SuggestedUse."
                }
                
                let alertAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    if let text = alertController.textFields?[0].text {
                        self?.suggestedUse = text
                    }
                }
                
                let cancel = UIAlertAction(title: "cancel", style: .destructive)
                
                alertController.addAction(alertAction)
                alertController.addAction(cancel)
                self.present(alertController, animated: true)
                
            case 3:
                let alertController = UIAlertController(title: "Type?", message: nil, preferredStyle: .alert)
                
                let nutrientAction = UIAlertAction(title: "nutrients", style: .default) { [weak self] _ in
                    self?.pillType = .nutrients
                    
                    self?.tableView.reloadData()
                }
                
                let pillAction = UIAlertAction(title: "Medicine", style: .default) { [weak self] _ in
                    self?.pillType = .medicine
                    self?.tableView.reloadData()
                }
                
                
                alertController.addAction(nutrientAction)
                alertController.addAction(pillAction)
                self.present(alertController, animated: true)
                
            default:
                break
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                CSPicker()
            default:
                let alertController = UIAlertController(title: "Delete?", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    self?.dates.remove(at: indexPath.row)
                }
                let cancel = UIAlertAction(title: "cancel", style: .destructive)
                alertController.addAction(alertAction)
                alertController.addAction(cancel)
                self.present(alertController, animated: true)
            }
            
        }
    }
   
    @objc
    func snoozeSwitchTapped (_ sender: UISwitch) {
        snoozeEnabled = sender.isOn
        
    }
    
    @objc
    func save() {
        var repeatableAlarm = RepeatableAlarm()
        repeatableAlarm.onSnooze = self.snoozeEnabled
        for date in dates {
            repeatableAlarm.dates.append(date)
        }
        repeatableAlarm.title = self.pillName ?? "Take a pill!"
        repeatableAlarm.suggestedUse = self.suggestedUse ?? ""
        for weekday in self.selectedWeekDays.weekdays {
            repeatableAlarm.repeatDays.append(weekday)
        }
        
        if let selectedImage {
            let imageId = UUID().uuidString
            repeatableAlarm.imageId = imageId
            ImageDataController.shared.save(alarm: repeatableAlarm, image: selectedImage, for: imageId)
        }

        DBService.shared.update(repeatableAlarm)
        PushNotificationManager.shared.scheduleNotification(reminder: repeatableAlarm)
        self.dismiss(animated: true)
    }
    
    @objc
    func CSPicker() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels

        
        let dateChooserAlert = UIAlertController(title: "ddd", message: nil, preferredStyle: .actionSheet)
        dateChooserAlert.view.addSubview(datePicker)
        dateChooserAlert.addAction(UIAlertAction(title: "Choose", style: .cancel, handler: { [weak self] _ in
            self?.dates.append(datePicker.date)
            self?.tableView.reloadData()
        }))
        datePicker.datePickerMode = .time

        dateChooserAlert.view.snp.makeConstraints { make in
            make.height.equalTo(300).multipliedBy(1.2)
        }
        
        present(dateChooserAlert, animated: true)
        
    }
    
    
    static func repeatText(weekdays: [Int]) -> String {
        if weekdays.count == 7 {
            return "Every day"
        }
        
        if weekdays.isEmpty {
            return "Never"
        }
        
        var ret = String()
        var weekdaysSorted:[Int] = [Int]()
        
        weekdaysSorted = weekdays.sorted(by: <)
        
        for day in weekdaysSorted {
            switch day{
            case 1:
                ret += "Sun "
            case 2:
                ret += "Mon "
            case 3:
                ret += "Tue "
            case 4:
                ret += "Wed "
            case 5:
                ret += "Thu "
            case 6:
                ret += "Fri "
            case 7:
                ret += "Sat "
            default:
                // break
                break
            }
        }
        return ret
    }
}

extension AlarmAddEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var pickedImage: UIImage?
        if let image = info[.editedImage] as? UIImage {
            self.selectedImage = image
            pickedImage = self.selectedImage
        } else if let image = info[.originalImage] as? UIImage {
            self.selectedImage = image
            pickedImage = self.selectedImage
        }
        
        guard let image = pickedImage else {
            if picker == imagePicker {
                imagePicker.dismiss(animated: true)
            } else {
                picker.dismiss(animated: true)
            }
            return
        }
        
        self.imageView.image = image

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if picker == imagePicker {
            imagePicker.dismiss(animated: true)
        } else {
            picker.dismiss(animated: true)
        }
    }
}

extension AlarmAddEditViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            var photoLibraryAction = UIAction(title: "", state: .off) { [weak self] _ in
                self?.presentImagePicker()
            }
            var cameraAction = UIAction(title: "", state: .off) { [weak self] _ in
                self?.presentCamera()
            }
            return UIMenu(title: "", children: [
                photoLibraryAction,
                cameraAction
            ])
        }
    }
}

class WeekDaysManager {
    var weekdays: [Int] = [] {
        didSet {
            self.didChagned = Void()
        }
    }
    
    var didChagned: Void = Void() {
        didSet {
            self.didChanged$.send(())
        }
    }
        
    
    var didChanged$ = PassthroughSubject<Void, Never>()
}


class AlarmTextFieldTableViewCell: UITableViewCell {
    static let identifier = "AlarmTextFieldTableViewCell"
    var textField = UITextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.add(textField) {
            $0.snp.makeConstraints { make in
                make.width.equalToSuperview().multipliedBy(0.4)
                make.leading.centerY.equalToSuperview()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AlarmNormalTableViewCell: UITableViewCell {
    static let identifier = "AlarmNormalTableViewCell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
