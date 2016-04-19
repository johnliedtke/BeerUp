import Foundation
import UIKit
import SugarRecord
import CoreData

class CoreDataBasicView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Attributes
    lazy var db: CoreDataDefaultStorage = {
        let store = CoreData.Store.Named("cd_basic")
        let bundle = NSBundle(forClass: CoreDataBasicView.classForCoder())
        let model = CoreData.ObjectModel.Merged([bundle])
        let defaultStorage = try! CoreDataDefaultStorage(store: store, model: model)
        return defaultStorage
    }()
    lazy var tableView: UITableView = {
        let _tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)
        _tableView.translatesAutoresizingMaskIntoConstraints = false
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "default-cell")
        return _tableView
    }()
    var entities: [CoreDataBasicEntity] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Init
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "CoreData Basic"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        updateData()
    }
    
    
    // MARK: - Private
    
    private func setup() {
        setupView()
        setupNavigationItem()
        setupTableView()
    }
    
    private func setupView() {
        self.view.backgroundColor = UIColor.whiteColor()
    }
    
    private func setupNavigationItem() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(CoreDataBasicView.userDidSelectAdd(_:)))
    }
    
    private func setupTableView() {
        self.view.addSubview(tableView)
        self.tableView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entities.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("default-cell")!
        cell.textLabel?.text = "\(entities[indexPath.row].name) - \(entities[indexPath.row].dateString)"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let name = entities[indexPath.row].name
            db.operation({ (context, save) -> Void in
                guard let obj = try! context.request(BasicObject.self).filteredWith("name", equalTo: name).fetch().first else { return }
                _ = try? context.remove(obj)
                _ = try? save()
            })
            updateData()
        }
    }
    
    
    // MARK: - Actions
    
    func userDidSelectAdd(sender: AnyObject!) {
        db.operation { (context, save) -> Void in
            let _object: BasicObject = try! context.new()
            _object.date = NSDate()
            _object.name = randomStringWithLength(10) as String
            try! context.insert(_object)
            _ = try? save()
        }
        updateData()
    }
    
    
    // MARK: - Private
    
    private func updateData() {
        self.entities = try! db.fetch(Request<BasicObject>()).map(CoreDataBasicEntity.init)
    }
}

class BasicObject: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    
}

extension BasicObject {
    
    @NSManaged var date: NSDate?
    @NSManaged var name: String?
    
}


class CoreDataBasicEntity {
    let dateString: String
    let name: String
    init(object: BasicObject) {
        let dateFormater = NSDateFormatter()
        dateFormater.timeStyle = NSDateFormatterStyle.ShortStyle
        dateFormater.dateStyle = NSDateFormatterStyle.ShortStyle
        self.dateString = dateFormater.stringFromDate(object.date!)
        self.name = object.name!
    }
}