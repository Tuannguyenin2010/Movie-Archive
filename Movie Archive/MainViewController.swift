import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var placeholderLabel: UILabel! 
    
    var movies: [Movie] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = "Back"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 130
        placeholderLabel.text = "Start by adding your first movie!"
        placeholderLabel.isHidden = true // Initially hide the placeholder
        NotificationCenter.default.addObserver(self, selector: #selector(fetchMovies), name: NSNotification.Name("MovieAdded"), object: nil)
        fetchMovies()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func addMovieButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showAdd", sender: self)
    }

    @objc func fetchMovies() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("movies").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching movies: \(error.localizedDescription)")
                self.showErrorAlert(message: "Error fetching movies: \(error.localizedDescription)")
            } else {
                self.movies = snapshot?.documents.compactMap { document -> Movie? in
                    try? document.data(as: Movie.self)
                } ?? []
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        }
    }

    func updateUI() {
        if movies.isEmpty {
            placeholderLabel.isHidden = false
            tableView.isHidden = true
        } else {
            placeholderLabel.isHidden = true
            tableView.isHidden = false
        }
        tableView.reloadData()
    }

    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = movies[indexPath.row]
        cell.configure(with: movie)
        return cell
    }

    // Enable swipe to delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let movie = movies[indexPath.row]
            deleteMovie(movie)
        }
    }

    func deleteMovie(_ movie: Movie) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("movies").document(movie.id).delete { error in
            if let error = error {
                print("Error deleting movie: \(error.localizedDescription)")
                self.showErrorAlert(message: "Error deleting movie: \(error.localizedDescription)")
            } else {
                self.movies.removeAll { $0.id == movie.id }
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        }
    }
}

class MovieCell: UITableViewCell {
    @IBOutlet weak var movieImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var criticsRatingLabel: UILabel!

    func configure(with movie: Movie) {
        nameLabel.text = movie.name
        yearLabel.text = "Release Year: \(movie.year)"
        criticsRatingLabel.text = "Rating: \(movie.criticsRating)"
        if let url = URL(string: movie.poster) {
            downloadImage(from: url)
        }
    }

    private func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self.movieImageView.image = UIImage(data: data)
            }
        }.resume()
    }
}

struct Movie: Codable {
    var id: String
    var name: String
    var poster: String
    var year: String
    var criticsRating: String
}
