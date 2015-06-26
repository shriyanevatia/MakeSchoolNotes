//
//  ViewController.swift
//  MakeSchoolNotes
//
//  Created by Martin Walsh on 29/05/2015.
//  Copyright (c) 2015 MakeSchool. All rights reserved.
//

import UIKit
import RealmSwift

class NotesViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    enum State {
        case DefaultMode
        case SearchMode
    }
    
    var state: State = .DefaultMode {
        didSet {
            // update notes and search bar whenever State changes
            switch (state) {
            case .DefaultMode:
                let realm = Realm()
                //We have moved our default state search code so whenever we return to default 
                // state the list is reset.
                notes = realm.objects(Note).sorted("modificationDate", ascending: false)
                
                // This returns the navigation bar in an animated fashion - you can see why 
                // it was hidden in point 6.
                self.navigationController!.setNavigationBarHidden(false, animated: true)
                
                // Remove keyboard popup.
                searchBar.resignFirstResponder()
                searchBar.text = ""
                searchBar.showsCancelButton = false
            case .SearchMode:
                let searchText = searchBar?.text ?? ""
                
                // Animate in a cancel button beside the search bar. This just looks nice (UI Polish).
                searchBar.setShowsCancelButton(true, animated: true)
                
                // Perform a search on any text entered into the search bar.
                notes = searchNotes(searchText)
                
                // This makes the search bar take prominence in our view. By hiding the 
                // navigation bar the user is focused on search. (UI Polish)
                self.navigationController!.setNavigationBarHidden(true, animated: true)
            }
        }
    }
    
    var selectedNote: Note? 

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let realm = Realm()
        notes = realm.objects(Note).sorted("modificationDate", ascending: false)
        state = .DefaultMode
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var notes: Results<Note>! {
        didSet {
            // Whenever notes update, update the table view
            tableView?.reloadData()
        }
    }
    
    @IBAction func unwindToSegue(segue: UIStoryboardSegue) {
        
        if let identifier = segue.identifier {
            let realm = Realm()
            switch identifier {
            case "Save":
                // We need to grab a reference to the outgoing controller, which in this case is our 
                // New Note View Controller. We do this to gain access to the currentNote variable 
                // that holds the new Note object.
                let source = segue.sourceViewController as! NewNoteViewController
                
                realm.write() {
                    realm.add(source.currentNote!)
                }
                
            case "Delete":
                realm.write() {
                    realm.delete(self.selectedNote!)
                }
                
                let source = segue.sourceViewController as! NoteDisplayViewController
                
                // QUESTION!!
                source.note = nil;
                
            default:
                println("No one loves \(identifier)")
            }
            
            // Realm allows for advanced sorting and query functionality for its stored objects.
            // Previously, we just grabbed all Note objects without any regard for order. This 
            // change makes the app more useful and orders by the most recent modificationDate.
            notes = realm.objects(Note).sorted("modificationDate", ascending: false)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ShowExistingNote") {
            let noteViewController = segue.destinationViewController as! NoteDisplayViewController
            noteViewController.note = selectedNote
        }
    }
}

extension NotesViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NoteCell", forIndexPath: indexPath) as! NoteTableViewCell //1
        
        let row = indexPath.row
        let note = notes[row] as Note
        cell.note = note
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // same as writing:
        // if let notes = notes {
        //      return Int(notes.count)
        // } else {
        //      return 0
        // }
        
        return Int(notes?.count ?? 0)
    }
    
}

extension NotesViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // When a note has been selected, we want to assign this note to a variable for easy access. 
        // When a row is selected, the row index is passed as a parameter so we can grab the correct 
        // note object using the objectAtIndex method.
        
        selectedNote = notes[indexPath.row]
        
        // We will be performing a segue to a new Note Display View Controller 
        // (you will add this soon) that will display the selected note.
        self.performSegueWithIdentifier("ShowExistingNote", sender: self)
    }
    
    // This function is used to check if a row can be edited. In our app we would always like 
    // this behaviour, so it will always return true.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // This function is activated when you left swipe your Table View to enter edit mode and 
    // are presented with the option to Delete the selected row.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            let note = notes[indexPath.row] as Object
            
            let realm = Realm()
            
            realm.write() {
                realm.delete(note)
            }
            
            notes = realm.objects(Note).sorted("modificationDate", ascending: false)
        }
    }
    
}

func searchNotes(searchString: String) -> Results<Note> {
    let realm = Realm()
    let searchPredicate = NSPredicate(format: "title CONTAINS[c] %@ OR content CONTAINS[c] %@", searchString, searchString)
    return realm.objects(Note).filter(searchPredicate)
}

extension NotesViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        state = .SearchMode
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        state = .DefaultMode
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        notes = searchNotes(searchText)
    }
    
}



