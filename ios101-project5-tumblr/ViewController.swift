//
//  ViewController.swift
//  ios101-project5-tumbler
//

import UIKit
import Nuke

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    // Store fetched posts here
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        
        fetchPosts()
    }

    func fetchPosts() {
        let url = URL(string: "https://api.tumblr.com/v2/blog/humansofnewyork/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk")!
        let session = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                return
            }

            guard let data = data else {
                print("❌ Data is NIL")
                return
            }

            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)

                DispatchQueue.main.async { [weak self] in
                    let posts = blog.response.posts

                    print("✅ We got \(posts.count) posts!")
                    for post in posts {
                        print("🍏 Summary: \(post.summary)")
                    }

                    // Save posts and reload table
                    self?.posts = posts
                    self?.tableView.reloadData()
                }

            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
            }
        }
        session.resume()
    }
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            fatalError("Could not dequeue PostCell")
        }

        let post = posts[indexPath.row]

        // Set the summary label
        cell.summaryLabel.text = post.summary

        // Load the image if available
        if let photo = post.photos.first {
            Nuke.ImagePipeline.shared.loadImage(with: photo.originalSize.url) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        cell.customImageView.image = response.image
                    }
                case .failure(let error):
                    print("Failed to load image: \(error)")
                    DispatchQueue.main.async {
                        cell.customImageView.image = nil
                    }
                }
            }

        } else {
            cell.customImageView.image = nil
        }

        return cell
    }
}
