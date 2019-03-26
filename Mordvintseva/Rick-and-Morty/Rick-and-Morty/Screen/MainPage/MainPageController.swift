//
//  ViewController.swift
//  Rick-and-Morty
//
//  Created by Mordvintseva Alena on 17/03/2019.
//  Copyright © 2019 Mordvintseva Alena. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire

class MainPageController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet var emptyView: UIView!
    private let dataBase = DBManager()
    private lazy var characters = dataBase.getAll()
    private var nextPageURL: String? = "https://rickandmortyapi.com/api/character/"
    private let cellIdentifier = "cell"
    private let characterService = CharacterServiceNetwork()
    private var networkIsReachable: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        if let reachable = NetworkReachabilityManager()?.isReachable {
            networkIsReachable = reachable
        }
        print(networkIsReachable)
        if networkIsReachable {
            loadNextPage()
        } else {
            characters = dataBase.getAll()
        }

        tableView.dataSource = self
        tableView.delegate = self
        let nib = UINib.init(nibName: "CharacterCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
    }

    func loadNextPage() {
        guard let nextPage = nextPageURL else {
            return
        }

        tableView.tableFooterView = loadingView
        print(nextPage)
        characterService.getCharacters(urlString: nextPage) { charactersData in
            //print(charactersData)
            for character in charactersData.results {
                let result = self.dataBase.search("id", character.id)
                if result.count == 0 {
                    print("add \(character.name)")
                    self.dataBase.add(character)
                }
            }
            self.nextPageURL = charactersData.info.next
        }
        self.characters = self.dataBase.getAll()
        //print(characters)
        DispatchQueue.main.async {
            self.tableView.tableFooterView = self.emptyView
            self.tableView.reloadData()
        }
    }
}

extension MainPageController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            as? CharacterCell else {
            fatalError("Cell cannot be displayed")
        }

        if indexPath.row == self.characters.count - 1, nextPageURL != nil, networkIsReachable {
            loadNextPage()
        }

        cell.set(name: self.characters[indexPath.row].name, imageURL: self.characters[indexPath.row].image)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characterController = storyboard?.instantiateViewController(withIdentifier: "CharacterView")
            as? CharacterViewController else { return }
        self.navigationController?.pushViewController(characterController, animated: true)
        characterController.setCharacter(character: characters[indexPath.row])
    }
}