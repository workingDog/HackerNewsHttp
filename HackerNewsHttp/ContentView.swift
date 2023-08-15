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
    @State var selection: ItemType = .top
    
    var body: some View {
        NavigationStack {
            VStack {
                ToolsView(selection: $selection).padding(5)
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
                Spacer()
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

struct ToolsView: View {
    @Binding var selection: ItemType
    
    var body: some View {
        Picker("Flavor", selection: $selection) {
            Text("Top").foregroundStyle(selection == ItemType.top ? .red : .blue)
                .tag(ItemType.top)
            Text("Ask").foregroundStyle(selection == ItemType.ask ? .red : .blue).tag(ItemType.ask)
            Text("Show").foregroundStyle(selection == ItemType.show ? .red : .blue)
                .tag(ItemType.show)
            Text("Jobs").foregroundStyle(selection == ItemType.jobs ? .red : .blue)
                .tag(ItemType.jobs)
        }
        .padding(5)
        .pickerStyle(.segmented)
        .background(Color.red.opacity(0.7))
        .cornerRadius(15)
        .frame(width: 256)
    //    .contentShape(RoundedRectangle(cornerRadius: 15))
    //    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray, lineWidth: 2))
    }
}

struct ToolsView2: View {
    @Binding var selection: ItemType
    
    var body: some View {
        VStack (spacing: 5) {
            Picker("Flavor", selection: $selection) {
                Text("Top").foregroundStyle(selection == ItemType.top ? .red : .blue)
                    .tag(ItemType.top)
                Text("Ask").foregroundStyle(selection == ItemType.ask ? .red : .blue).tag(ItemType.ask)
                Text("Show").foregroundStyle(selection == ItemType.show ? .red : .blue)
                    .tag(ItemType.show)
                Text("Jobs").foregroundStyle(selection == ItemType.jobs ? .red : .blue)
                    .tag(ItemType.jobs)
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                Image(systemName: "flame")
                    .foregroundStyle(selection == ItemType.top ? .white : .blue)
                Spacer()
                Image(systemName: "person.fill.questionmark")
                    .foregroundStyle(selection == ItemType.ask ? .white : .blue)
                Spacer()
                Image(systemName: "eye")
                    .foregroundStyle(selection == ItemType.show ? .white : .blue)
                Spacer()
                Image(systemName: "briefcase")
                    .foregroundStyle(selection == ItemType.jobs ? .white : .blue)
                Spacer()
            }//.padding(.leading, 3)
        }
        .padding(5)
        .pickerStyle(.segmented)
        .background(Color.red.opacity(0.8))
        .cornerRadius(15)
        .frame(width: 256)
    }
}

#Preview {
    ContentView()
}
