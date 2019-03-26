import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    var todoItems: Results<Item>?
    let realm = try! Realm()
    @IBOutlet weak var searchBar: UISearchBar!
    
    var selectedCategory : Category? {
        didSet {
            loadItems()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        title = selectedCategory?.name

        guard let colorHex = selectedCategory?.color  else { fatalError("Error occurred") }
        
        updateNavBar(withHexCode: colorHex)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        guard let originalColor = UIColor(hexString: "1D9BF6") else {fatalError()}
        
        updateNavBar(withHexCode: "1D9BF6")
    }
    
    //MARK:- Nav bar setup methods
    
    func updateNavBar(withHexCode colorHexCode: String) {
        guard let navBar = navigationController?.navigationBar else {
            fatalError("Navigation Controller does not exist")
        }
        
        guard let navBarColor = UIColor(hexString: colorHexCode) else { fatalError("nav bar error occurred") }
        
        navBar.barTintColor = navBarColor
        
        navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
        
        if #available(iOS 11.0, *) {
            navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ContrastColorOf(navBarColor, returnFlat: true)]
        } else {
            // Fallback on earlier versions
        }
        
        searchBar.barTintColor = navBarColor
    }
    
    // MARK - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            cell.textLabel?.text = item.title
            
            if let color = UIColor(hexString: selectedCategory!.color)?.darken(byPercentage:CGFloat(indexPath.row) / CGFloat(todoItems!.count)) {
                cell.backgroundColor = color
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            }
            
            

            //Ternary operator:
            //value = condition ? valueIfTRue : valueIfFalse
            
            cell.accessoryType = item.isDone ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    
                    item.isDone = !item.isDone
                }
            } catch {
                print("Error saving done status: \(error)")
            }
        }
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK - add new items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todaily Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) {
            (action) in
            //what will happen when the user clicks Add Item button on our UIAlert
            
            if let currenctCategory = self.selectedCategory {
                do{
                    try self.realm.write { 
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currenctCategory.items.append(newItem)
                    }
                } catch {
                    print("Error saving new items: \(error)")
                }
            }
            self.tableView.reloadData()
        }
        alert.addTextField {
            
            (alertTextField) in
            
            alertTextField.placeholder = "Create a New Item"
            textField = alertTextField
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK - Model Manipulation Methods
    
//    func saveItems() {
//
//        do {
//           try context.save()
//        } catch {
//            print("Error saving context: \(error)")
//        }
//
//        self.tableView.reloadData()
//    }
    
    func loadItems() {
        
        todoItems = selectedCategory?.items.sorted(byKeyPath: "dateCreated", ascending: false)

        tableView.reloadData()
    }
    
    override func updateModel(at indexPath: IndexPath) {
        if let item = todoItems?[indexPath.row] {
            
            do{
               try realm.write {
                    realm.delete(item)
                }
            } catch {
                print("Error deleting cells: \(error)")
            }
        }
    }

}

//MARK: Seacrh Bar Methods
// Here we can set the listing order of the items by changing the keyPath and ascending orders

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
