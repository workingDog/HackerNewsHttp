//
//  HNProvider.swift
//  HackerNewsHttp
//
//  Created by Ringo Wathelet on 2023/07/28.
//

import Foundation
import SwiftUI
import Observation


// https://github.com/HackerNews/API
// https://myafka.github.io/HN-API-Docs/


// not used
struct HNUser: Identifiable, Codable {
    let id: String
    let created: Int
    let karma: Int
    let about: String?
    let submitted: [Int]?
}

enum StoryType: String {
    case top, new, show, ask, jobs, poll
}

enum Endpoints: String {
    case item, user, topstories, newstories, askstories, jobstories, showstories
}

// list of all items properties
struct HNItem: Identifiable, Codable {
    let id: Int             // required, the item's unique id.
    let type: String        // One of "job", "story", "comment", "poll", or "pollopt"
    var title: String?      // The title of the story, poll or job. HTML.
    var url: String?        // The URL of the story.
    var by: String?         // The username of the item's author.
    var score: Int?         // The story's score, or the votes for a pollopt.
    var descendants: Int?   // In the case of stories or polls, the total comment count.
    var time: Int = 0       // Creation date of the item, in Unix Time.
    var kids: [Int]?        // The ids of the item's comments, in ranked display order.
    var text: String?       // The comment, story or poll text. HTML.
    var deleted: Bool?      // true if the item is deleted.
    var dead: Bool?         // true if the item is dead.
    var parent: Int?        // The comment's parent: either another comment or the relevant story.
    var poll: String?       // The pollopt's associated poll.
    var parts: [Int]?       // A list of related pollopts, in display order.
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: Date(timeIntervalSince1970: TimeInterval(time)), relativeTo: Date()).lowercased()
    }
   
}

struct Story: Identifiable, Codable {
    let id: Int             // required, the item's unique id.
    let type: String        // One of "job", "story", "comment", "poll", or "pollopt"
    var title: String?      // The title of the story, poll or job. HTML.
    var url: String?        // The URL of the story.
    var by: String?         // The username of the item's author.
    var score: Int?         // The story's score, or the votes for a pollopt.
    var descendants: Int?   // In the case of stories or polls, the total comment count.
    var time: Int = 0       // Creation date of the item, in Unix Time.
    var kids: [Int]?        // The ids of the item's comments, in ranked display order.
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: Date(timeIntervalSince1970: TimeInterval(time)), relativeTo: Date()).lowercased()
    }
    
}

struct Comment: Identifiable, Codable {
    let id: Int             // required, the item's unique id.
    let type: String        // One of "job", "story", "comment", "poll", or "pollopt"
    var text: String?       // The comment, story or poll text. HTML.
    var by: String?         // The username of the item's author.
    var kids: [Int]?        // The ids of the item's comments, in ranked display order.
    var parent: Int?        // The comment's parent: either another comment or the relevant story.
    var time: Int = 0       // Creation date of the item, in Unix Time.
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: Date(timeIntervalSince1970: TimeInterval(time)), relativeTo: Date()).lowercased()
    }
    
}

@Observable class StoriesModel {
    var topStoriesId: [Int] = []
    var stories: [Story] = []
    var comments: [Comment] = []
    var storyType: StoryType = .new
    
    // @ObservationIgnored @AppStorage("selectedType") var selectedType: StoryType = .new
    @ObservationIgnored static let databaseURL = "https://hacker-news.firebaseio.com"
    @ObservationIgnored let maxStories = 50
    
    func getStory(_ id: Int) async -> Story? {
        if let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return try JSONDecoder().decode(Story.self, from: data)
            } catch {
                print(error)
            }
        }
        return nil
    }
    
    func getTopstoriesIds() async {
        if let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let results = try JSONDecoder().decode([Int].self, from: data)
                self.topStoriesId = Array(results[..<maxStories])
                //Array(results[..<maxStories])
                //Array(results.prefix(maxStories))
            } catch {
                print(error)
            }
        }
    }
    
    func getTopstories() async {
        // for testing, don't reload, just do it once
        if topStoriesId.count > 0 {
            return
        }
        stories.removeAll()
        topStoriesId.removeAll()
        await getTopstoriesIds()
        await withTaskGroup(of: Story?.self) { group in
            for id in self.topStoriesId {
                group.addTask { await self.getStory(id) }
            }
            for await story in group {
                if let story = story {
                    stories.append(story)
                }
            }
        }
    }
    
    func getComments(for story: Story) async {
        comments.removeAll()
        await withTaskGroup(of: Comment?.self) { group in
            for id in story.kids ?? [] {
                group.addTask { await self.getComment(id) }
            }
            for await cmt in group {
                if let cmt = cmt {
                    comments.append(cmt)
                }
            }
        }
    }
    
    func getComment(_ id: Int) async -> Comment? {
        if let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return try JSONDecoder().decode(Comment.self, from: data)
            } catch {
                print(error)
            }
        }
        return nil
    }
    
}
