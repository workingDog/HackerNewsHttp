//
//  ContentView.swift
//  HackerNewsHttp
//
//  Created by Ringo Wathelet on 2023/07/28.
//

import Foundation
import SwiftUI
import Observation


struct ContentView: View {
    @State private var storiesModel = StoriesModel()
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else {
                List(storiesModel.stories.sorted(by: {$0.time > $1.time })) { story in
                    NavigationLink(destination: StoryView(story: story)) {
                        ListRowView(story: story)
                    }
                    .listRowBackground(Color.cyan.opacity(0.1))
                }
            }
        }
        .environment(storiesModel)
     //   .navigationBarHidden(true)
        .navigationTitle("Hacker News")
        .task {
            isLoading = true
            await storiesModel.getTopstories()
            isLoading = false
        }
    }
}

struct ListRowView: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(story.title ?? "").bold()
            HStack {
                VStack (alignment: .leading) {
                    Text(story.timeAgo)
                    Text("by \(story.by ?? "")")
                }
                Spacer()
            }.italic().foregroundColor(Color.pink)
        }
    }
}

#Preview {
    ContentView()
}
