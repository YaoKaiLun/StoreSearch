//
//  ViewController.swift
//  StoreSearch
//
//  Created by kailun on 2019/6/15.
//  Copyright © 2019 kailun.com. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    var hasSearch = false
    var isLoading = false
    var dataTask: URLSessionDataTask?
    var landscapeVC: LandscapeViewController?
    
    struct TableView {
        struct CellIdentifiers {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let loadingCell = "LoadingCell"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var cellNib = UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.searchResultCell)

        cellNib = UINib(nibName: TableView.CellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableView.CellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
        
        searchBar.barTintColor = UIColor(red: 20/225, green: 160/225, blue: 160/225, alpha: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let controller = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = searchResults[indexPath.row]
            controller.searchResult = searchResult
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        switch newCollection.verticalSizeClass {
        case .compact:
            showLandscape(with: coordinator)
        case .regular, .unspecified:
            hideLandscape(with: coordinator)
        }
    }
    
    func iTunesUrl(searchText: String, category: Int) -> URL {
        let kind: String
        switch category {
            case 1: kind = "musicTrack"
            case 2: kind = "software"
            case 3: kind = "ebook"
            default: kind = ""
        }
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200&entity=\(kind)", encodedText)
        let url = URL(string: urlString)
        return url!
    }
    
    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            return result.results
        } catch {
            print("Parse JSON Error: \(error)")
            return []
        }
    }
    
    func showNetworkError() {
        let alert = UIAlertController(
            title: "Whoops...",
            message: "There was an error accessing the iTunes Store. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        ))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    func performSearch() {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            hasSearch = true
            searchResults = []
            isLoading = true
            tableView.reloadData()
            let url = iTunesUrl(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
            
            let session = URLSession.shared
            dataTask?.cancel()
            dataTask = session.dataTask(with: url) {
                data, response, error in
                if let error = error as NSError?, error.code == -999 {
                    return
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data {
                        self.searchResults = self.parse(data: data)
                        self.searchResults.sort(by: { result1, result2 in
                            result1.name.localizedStandardCompare(result2.name) == .orderedAscending
                        })
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    print("Failure! \(response!)")
                }
            }
            dataTask?.resume()
        }
        
        searchBar.resignFirstResponder()
    }
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if landscapeVC != nil {
            return
        }
        
        landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        if let controller = landscapeVC {
            controller.searchResults = searchResults
            controller.view.frame = view.bounds
            view.addSubview(controller.view)
            addChild(controller)
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
            }, completion: { _ in
                controller.didMove(toParent: self)
            })
            
            if self.presentedViewController != nil {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeVC {
            controller.willMove(toParent: nil)
            
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 0
            }, completion: { _ in
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self.landscapeVC = nil
            })
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        }

        if !hasSearch {
            return 0
        }
        
        if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.loadingCell, for: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        }

        if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.configure(for: searchResult)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    // for the "Nothing Found" cell
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}
