import UIKit
import Combine
import AddThen

class AlarmSettingViewController: UIViewController {
    typealias Core = AlarmSettingCore
    private var core = Core()
    private var subscription = Set<AnyCancellable>()
    private var tableView = UITableView(frame: .zero, style: .insetGrouped)
    var refreshControl = UIRefreshControl()
    private var saveBarButton: UIBarButtonItem!
    private lazy var saveAction = UIAction { [weak self] _ in
        self?.addAlarmAction()
    }
    
    static func instantiate(
    ) -> UINavigationController {
        let vc = AlarmSettingViewController()
        let navigation = UINavigationController(rootViewController: vc)
        return navigation
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bind(core: core)
        
    }
    
    private func initView() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        saveBarButton = UIBarButtonItem(systemItem: .add, primaryAction: saveAction)
        saveBarButton.tintColor = .systemGray2
        navigationItem.rightBarButtonItems = [saveBarButton]
        navigationItem.title = "Pill"
        
        
        view.add(tableView) {
            $0.delegate = self
            $0.dataSource = self
            $0.refreshControl = self.refreshControl
            $0.register(AlarmSettingTableViewCell.self, forCellReuseIdentifier: AlarmSettingTableViewCell.identifier)
            $0.register(AlarmSettingAddTableViewCell.self, forCellReuseIdentifier: AlarmSettingAddTableViewCell.identifier)
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        self.refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        
        PushNotificationManager.shared.requestAuthorization()
    }
    
    private func bind(core: Core) {
        core.$alarms
            .assertNoFailure()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .sink { [weak self] alarms in
                self?.tableView.reloadData()
            }
            .store(in: &subscription)
    }
}

extension AlarmSettingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
            return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return core.alarms.count
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1, let cell = tableView.dequeueReusableCell(withIdentifier: AlarmSettingAddTableViewCell.identifier, for: indexPath) as? AlarmSettingAddTableViewCell {
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlarmSettingTableViewCell.identifier, for: indexPath) as? AlarmSettingTableViewCell else { return UITableViewCell() }
        
        cell.selectionStyle = .none
        cell.tag = indexPath.row
        let alarm = core.alarms[indexPath.row]

        //append switch button
        let sw = cell.switch
        
        //tag is used to indicate which row had been touched
        sw.tag = indexPath.row
        sw.addTarget(self, action: #selector(self.switchTapped(_:)), for: .valueChanged)
        if alarm.isEnable {
            cell.backgroundColor = UIColor.white
            
            cell.isEnableAlpha = 1.0
            
            sw.setOn(true, animated: false)
        } else {
            cell.backgroundColor = UIColor.systemGroupedBackground
            cell.isEnableAlpha = 0.5
        }
        
        cell.configure(repeatableAlarm: alarm)
        
        //delete empty seperator line
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == core.alarms.count {
            let cell = tableView.cellForRow(at: indexPath)
            cell?.setSelected(true, animated: true)
            cell?.setSelected(false, animated: true)
            self.addAlarmAction()
        }
    }
    
    @objc
    private func switchTapped(_ sender: UISwitch) {
        core.changeAlarmIsEnable(index: sender.tag, isEnable: sender.isOn)
    }
    
    @objc
    private func refresh() {
        self.tableView.reloadData()
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func addAlarmAction() {
        let vc = AlarmAddEditViewController()
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
}

class AlarmSettingCore: ObservableObject {
    private var subscription = Set<AnyCancellable>()
    private let dbService = DBService.shared
    @Published var alarms: [RepeatableAlarm] = []
    
    init () {
        dbService.realm.objects(RepeatableAlarm.self)
            .collectionPublisher
            .map { results -> [RepeatableAlarm] in
                let predicate = NSPredicate(format: "isActive == true")
                let _results = results.filter(predicate)
                return Array(_results)
            }
            .assertNoFailure()
            .assign(to: &self.$alarms)
    }
    
    
    func changeAlarmIsEnable(index: Int, isEnable: Bool) {
        
        let alarm = self.alarms[index]
        
        let newAlarm = RepeatableAlarm(value: alarm)
        newAlarm.isEnable = isEnable
        AlarmService.shared.set(repeatable: newAlarm, isUpdate: true)
    }
}

class AlarmSettingTableViewCell: UITableViewCell {
    static let identifier = "AlarmSettingTableViewCell"
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let timeLabel = UILabel()
    private let dateLabel = UILabel()

    var `switch` = UISwitch()
    
    var isEnableAlpha: CGFloat = 1 {
        didSet {
            self.titleLabel.alpha = isEnableAlpha
            self.subTitleLabel.alpha = isEnableAlpha
            self.iconImageView.alpha = isEnableAlpha
            self.timeLabel.alpha = isEnableAlpha
            self.dateLabel.alpha = isEnableAlpha
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryView = self.switch
        
        
        contentView.add(iconImageView) {
            $0.layer.cornerRadius = 8
            $0.layer.masksToBounds = true
            $0.snp.makeConstraints { make in
                make.height.width.equalTo(64)
                make.top.equalToSuperview().inset(16)
                make.leading.equalToSuperview().inset(16)
            }
        }
        contentView.add(titleLabel) {
            $0.font = .preferredFont(forTextStyle: .title1)
            $0.snp.makeConstraints { make in
                make.top.equalTo(self.iconImageView)
                make.leading.equalTo(self.iconImageView.snp.trailing).offset(16)
            }
        }
        
        contentView.add(subTitleLabel) {
            $0.font = .preferredFont(forTextStyle: .subheadline)
            $0.snp.makeConstraints { make in
                make.bottom.equalTo(self.iconImageView)
                make.leading.equalTo(self.iconImageView.snp.trailing).offset(16)
            }
        }
        
        contentView.add(dateLabel) {
            $0.font = .preferredFont(forTextStyle: .caption1)
            $0.snp.makeConstraints { make in
                make.top.equalTo(self.subTitleLabel.snp.bottom).offset(12)
                make.leading.equalTo(self.iconImageView.snp.trailing).offset(16)
            }
        }
        
        contentView.add(timeLabel) {
            $0.font = .preferredFont(forTextStyle: .caption1)
            $0.snp.makeConstraints { make in
                make.top.equalTo(self.dateLabel.snp.bottom).offset(4)
                make.leading.equalTo(self.iconImageView.snp.trailing).offset(16)
                make.bottom.equalToSuperview().inset(16)
            }
        }
        
    }
            
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(repeatableAlarm: RepeatableAlarm) {
        self.titleLabel.text = repeatableAlarm.title
        self.subTitleLabel.text = repeatableAlarm.suggestedUse
        self.dateLabel.text = nil
        var dateText = ""
        for date in repeatableAlarm.dates {
            dateText += date.formattedTime + ", "
        }
        self.dateLabel.text = dateText
        self.timeLabel.text = AlarmAddEditViewController.repeatText(weekdays: Array(repeatableAlarm.repeatDays))
        
        if let _ = repeatableAlarm.imageId {
            ImageDataController.shared.getThumbnailImage(alarm: repeatableAlarm) { [weak self] image in
                self?.iconImageView.image = image
            }
            
        } else {
            if let pillType = PillType(rawValue: repeatableAlarm.pillType) {
                switch pillType {
                case .medicine:
                    self.iconImageView.image = UIImage(named: "pill")
                case .nutrients:
                    self.iconImageView.image = UIImage(named: "pillRound")
                }
            }
            
        }

        self.switch.isOn = repeatableAlarm.isEnable
    }
}

class AlarmSettingAddTableViewCell: UITableViewCell {
    static let identifier = "AlarmSettingAddTableViewCell"
    private var plusImageView = UIImageView(image: UIImage(systemName: "plus")?.withTintColor(.tertiaryLabel))
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.add(UIView()) {
            $0.backgroundColor = .quaternaryLabel
            $0.layer.cornerRadius = 32
            $0.layer.masksToBounds = true
            $0.snp.makeConstraints { make in
                make.width.height.equalTo(64)
                make.center.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(16)
            }
            
            $0.add(self.plusImageView) {
                $0.tintColor = .secondaryLabel
                $0.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(32)
                }
            }
        }
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
