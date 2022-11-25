import UIKit
import Combine

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
        
        PushNotificationManager.shared.onTest()
    }
    
    private func initView() {
        tableView.backgroundColor = .systemGroupedBackground
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
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        self.refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        
        PushNotificationManager.shared.requestAuthorization()
    }
    
    private func bind(core: Core) {
        core.$alarms
            .sink { [weak self] alarms in
                print("🥶 bindbind \(alarms.count)")
                self?.tableView.reloadData()
            }
            .store(in: &subscription)
    }
}

extension AlarmSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("🥶 core.alarms.count\(core.alarms.count)")
        return core.alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlarmSettingTableViewCell.identifier, for: indexPath) as? AlarmSettingTableViewCell else { return UITableViewCell() }
        
        cell.selectionStyle = .none
        cell.tag = indexPath.row
        let alarm = core.alarms[indexPath.row]
        let amAttr: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20.0)]
//        let str = NSMutableAttributedString(string: alarm.formattedTime, attributes: amAttr)
        let str = NSMutableAttributedString(string: alarm.title, attributes: amAttr)
        let timeAttr: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 45.0)]
        str.addAttributes(timeAttr, range: NSMakeRange(0, str.length-2))
        cell.textLabel?.attributedText = str
        cell.detailTextLabel?.text = alarm.title
        //append switch button
        let sw = cell.switch
        
        //tag is used to indicate which row had been touched
        sw.tag = indexPath.row
        sw.addTarget(self, action: #selector(self.switchTapped(_:)), for: .valueChanged)
        if alarm.isEnable {
            cell.backgroundColor = UIColor.white
            cell.textLabel?.alpha = 1.0
            cell.detailTextLabel?.alpha = 1.0
            sw.setOn(true, animated: false)
        } else {
            cell.backgroundColor = UIColor.systemGroupedBackground
            cell.textLabel?.alpha = 0.5
            cell.detailTextLabel?.alpha = 0.5
        }
        
        //delete empty seperator line
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        cell.backgroundColor = .red
        
        return cell
    }
    
    @objc
    private func switchTapped(_ sender: UISwitch) {
        
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
//        let a =
        dbService.realm.objects(RepeatableAlarm.self)
            .collectionPublisher
            .map { results -> [RepeatableAlarm] in
                let predicate = NSPredicate(format: "isActive == true")
                let _results = results.filter(predicate)
                return Array(_results)
            }
            .print("🥶👀11")
            .assertNoFailure()
            .print("🥶👀22")
            .assign(to: &self.$alarms)
//            .assign(to: \.alarms, on: self)
//            .sink { error in
//                print("assa\(error)")
//            } receiveValue: { [weak self] alarsm in
//                self?.alarms = alarsm
//            }
//            .store(in: &subscription)
    }

}

class AlarmSettingTableViewCell: UITableViewCell {
    static let identifier = "AlarmSettingTableViewCell"
    var `switch` = UISwitch()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryView = self.switch
    }
            
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
