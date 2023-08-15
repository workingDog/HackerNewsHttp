//
//  Coview.swift
//  HackerNewsHttp
//
//  Created by Ringo Wathelet on 2023/07/28.
//

import Foundation
import SwiftUI
import Observation
import WebKit


struct StoryView: View {
    @Environment(StoriesModel.self) private var storiesModel
    let story: Story
    
    var body: some View {
        VStack(spacing: 10) {
            Text(story.by ?? "").bold().italic().foregroundStyle(.pink)
            Text(story.title ?? "").bold().padding(5)
            List(storiesModel.comments.sorted(by: {$0.time > $1.time })) { cmt in
                CommentView(comment: cmt).id(cmt.id)
                    .frame(height: 333)
                  //  .scaledToFit()
            }
//            .refreshable {
//                await storiesModel.getComments(for: story)
//            }
//            .listStyle(.plain)
        }
        .task {
            await storiesModel.getComments(for: story)
        }
    }
}

struct CommentView: View {
    let comment: Comment
    @State var urlRequest: URLRequest?
    
    var body: some View {
        ZStack {
            Color(.white).edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                HTMLView(html: comment.text ?? "", url: nil) { request in
                    urlRequest = request
                }
                Text("\(comment.by ?? "")     \(comment.timeAgo)")
                    .font(.custom("Lato-Regular", size: 16))
                    .foregroundColor(Color.teal)
                    .padding(10)
                
                Text("kids: \(comment.kids?.count ?? 0)")
                
            }
        }
        .sheet(item: $urlRequest) { req in
            LinkView(url: req.url)
        }
    }
}

struct LinkView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    let url: URL?
    
    @State var urlRequest: URLRequest?
    
    var body: some View {
        VStack {
#if targetEnvironment(macCatalyst)
            HStack {
                Button("Done") { dismiss() }.padding(10)
                Spacer()
            }
#endif
            
            HTMLView(html: "", url: url) { request in
                urlRequest = request
              //  if let url = request.url {
                    // opens the web browser
               //     openURL(url)
              //  }
            }
            Spacer()
        }
    }
}

extension URLRequest: Identifiable {
    public var id: URL? { url }
}

struct HTMLView: UIViewRepresentable {
    @Environment(\.openURL) var openURL
    
    let html: String
    let url: URL?
    
    let fontName = "PFHandbookPro-Regular"  // "sans-serif"   // system-ui
    
#if targetEnvironment(macCatalyst)
    @State var fontSize = "1.5em"
#elseif os(iOS)
    @State var fontSize = "3.8em"
#endif
    
    let handler: (URLRequest) -> Void
    
    let webView = WKWebView()
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        if let linkUrl = url {
            webView.load(URLRequest(url: linkUrl))
        } else {
            let fontSetting = "<span style=\"font-family: \(fontName);font-size: \(fontSize)\"</span>"
            webView.loadHTMLString(fontSetting + html, baseURL: nil)
          //  webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> HTMLView.Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: HTMLView
        
        init(_ parent: HTMLView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            guard let _ = navigationAction.request.url,
                    navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            
            if let url = navigationAction.request.url {
                // opens the web browser
                parent.openURL(url)
            }
            
         //   parent.handler(navigationAction.request)
        }
    }
}
  
