import AddThen
import UIKit

class WeekdaysViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var weekdays: WeekDaysManager
    var weekDaysString: [String] = [
        "Every Sunday",
        "Every Monday",
        "Every Tuesday",
        "Every Wednesday",
        "Every Thursday",
        "Every Friday",
        "Every Saturday",
    ]
    var tableView: UITableView = .init(frame: .zero, style: .insetGrouped)
    
    init(weekdays: WeekDaysManager) {
        self.weekdays = weekdays
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.add(tableView) {
            $0.delegate = self
            $0.dataSource = self
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "\(Self.self)")

        for weekday in weekdays.weekdays
        {
            if weekday == (indexPath.row + 1) {
                cell.accessoryType = .checkmark
            }
        }
        
        cell.textLabel?.text = self.weekDaysString[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        
        if let index = weekdays.weekdays.index(of: (indexPath.row + 1)) {
            weekdays.weekdays.remove(at: index)
            cell.setSelected(true, animated: true)
            cell.setSelected(false, animated: true)
            cell.accessoryType = .none
        }
        else{
            //row index start from 0, weekdays index start from 1 (Sunday), so plus 1
            weekdays.weekdays.append(indexPath.row + 1)
            cell.setSelected(true, animated: true)
            cell.setSelected(false, animated: true)
            cell.accessoryType = .checkmark
            
        }
    }
}


extension WeekdaysViewController {
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
                //throw
                break
            }
        }
        return ret
    }
}
