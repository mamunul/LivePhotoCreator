//
//  ContentView.swift
//  Created by Mamunul Mazid on 3/8/21.
//

import PhotosUI
import SwiftUI

struct LivePhotoView: UIViewRepresentable {
    @Binding var livePhoto: PHLivePhoto?
    
    func makeUIView(context: Context) -> PHLivePhotoView {
        let liveView = PHLivePhotoView()
        return liveView
    }
    
    func updateUIView(_ lpView: PHLivePhotoView, context: Context) {
        lpView.livePhoto = livePhoto
    }
}

let presenter = MainPresenter()

struct LiveSwiftUIView: View {
    @State var livePhoto: PHLivePhoto?
    var body: some View {
        LivePhotoView(livePhoto: $livePhoto)
    }
}

struct ContentView: View {
    @State var showLivePhoto = false
    @State var livePhoto: PHLivePhoto?
    var body: some View {
        VStack {
            Button {
                presenter.generateLivePhoto { photo in
                    if photo != nil {
                        livePhoto = photo!
                        showLivePhoto = true
                    }
                }
                
            } label: {
                Text("showLivePhoto").padding()
            }
        }
        .sheet(isPresented: $showLivePhoto) {
            LivePhotoView(livePhoto: $livePhoto)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
