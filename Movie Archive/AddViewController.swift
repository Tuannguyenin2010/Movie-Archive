import UIKit
import FirebaseAuth
import FirebaseFirestore

class AddViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!

    var searchResults: [Movie] = []
    var selectedMovie: Movie?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = "Back"
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 130
        saveButton.isHidden = true
        updateLogoVisibility() 
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        searchMovies(query: searchText)
    }

    func searchMovies(query: String) {
        let urlString = "https://www.omdbapi.com/?s=\(query)&apikey=29eb3dea"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching movies: \(error.localizedDescription)")
                self.showErrorAlert(message: "Error fetching movies: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let result = try JSONDecoder().decode(OMDBResponse.self, from: data)
                let movies = result.Search.compactMap { searchResult -> Movie? in
                    Movie(id: UUID().uuidString, name: searchResult.Title, poster: searchResult.Poster, year: searchResult.Year, criticsRating: "")
                }
                self.fetchMovieDetails(for: movies)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                self.showErrorAlert(message: "Error decoding data: \(error.localizedDescription)")
            }
        }.resume()
    }

    func fetchMovieDetails(for movies: [Movie]) {
        let group = DispatchGroup()

        var detailedMovies: [Movie] = []
        for movie in movies {
            group.enter()
            let urlString = "https://www.omdbapi.com/?t=\(movie.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&apikey=29eb3dea"
            guard let url = URL(string: urlString) else {
                group.leave()
                continue
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching movie details: \(error.localizedDescription)")
                } else if let data = data {
                    do {
                        let detailedResult = try JSONDecoder().decode(OMDBMovieDetail.self, from: data)
                        var updatedMovie = movie
                        updatedMovie.criticsRating = detailedResult.imdbRating
                        detailedMovies.append(updatedMovie)
                    } catch {
                        print("Error decoding movie details: \(error.localizedDescription)")
                    }
                }
                group.leave()
            }.resume()
        }

        group.notify(queue: .main) {
            self.searchResults = detailedMovies
            self.updateLogoVisibility()
            self.tableView.reloadData()
        }
    }

    func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // Update logo visibility based on whether there are search results
    func updateLogoVisibility() {
        logoImageView.isHidden = !searchResults.isEmpty
        tableView.isHidden = searchResults.isEmpty
    }

    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! MovieCell
        let movie = searchResults[indexPath.row]
        cell.configure(with: movie)
        return cell
    }

    // UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMovie = searchResults[indexPath.row]
        saveButton.isHidden = false
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let movie = selectedMovie, let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("movies").document(movie.id).setData([
            "id": movie.id,
            "name": movie.name,
            "poster": movie.poster,
            "year": movie.year,
            "criticsRating": movie.criticsRating
        ]) { error in
            if let error = error {
                print("Error saving movie: \(error.localizedDescription)")
                self.showErrorAlert(message: "Error saving movie: \(error.localizedDescription)")
            } else {
                NotificationCenter.default.post(name: NSNotification.Name("MovieAdded"), object: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

struct OMDBResponse: Codable {
    let Search: [OMDBMovie]
}

struct OMDBMovie: Codable {
    let Title: String
    let Poster: String
    let Year: String
}

struct OMDBMovieDetail: Codable {
    let imdbRating: String
}


