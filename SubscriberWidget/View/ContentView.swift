//
//  ContentView.swift
//  SubscriberWidget
//
//  Created by Arjun Dureja on 2020-09-24.
//  Copyright © 2020 Arjun Dureja. All rights reserved.
//

import SwiftUI
import UIKit
import WidgetKit

struct ContentView: View {
    @AppStorage("channel", store: UserDefaults(suiteName: "group.com.arjundureja.SubscriberWidget")) var channelData: Data = Data()
    
    @ObservedObject var viewModel = ViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var name: String = ""
    @State private var showingAlert = false
    @State public var widgetSize = 0
    @State private var animate = false
    @State private var rotateIn3D = false
    @State private var helpAlert = false
    
    init() {
        // Segmented control colors
        UISegmentedControl.appearance().backgroundColor = .systemGray6
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.youtubeRed)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.systemBackground], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("SubWidget")
                .foregroundColor(Color(UIColor.label))
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 220, height: 42, alignment: .center)
                        .foregroundColor(Color(UIColor.systemBackground))
                    HStack {
                        if name.isEmpty {
                            Text("Channel Username or ID")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                            .frame(width: 6)
                    }
                    TextField("", text: $name)
                        .padding(10)
                        .frame(width: 220)
                        .foregroundColor(Color(UIColor.label))
                        .cornerRadius(8)
                        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10))
                }
                
                Button(action: {
                    if name.count > 0 {
                        self.viewModel.getChannelDetails(for: name) { (success, channel) in
                            if success {
                                UIApplication.shared.endEditing()
                                guard let channelData = try? JSONEncoder().encode(channel!.channelId) else { return }
                                self.channelData = channelData
                                WidgetCenter.shared.reloadAllTimelines()
                            } else {
                                self.showingAlert = true
                            }
                            name.removeAll()
                        }
                    }
                }, label: {
                    Text("Submit")
                        .foregroundColor(Color(UIColor.systemBackground))
                        .bold()
                })
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                .foregroundColor(.white)
                .font(.subheadline)
                .background(Color.youtubeRed)
                .cornerRadius(8)
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 20))
            }
            
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .frame(width: self.animate ? 329 : 155, height: 155, alignment: .leading)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .shadow(radius: 22)
                    .animation(.easeInOut(duration: 0.25))
                
                SmallWidget(entry: YouTubeChannel(channelName: "\(viewModel.channelDetails[0].channelName)", profileImage: "\(viewModel.channelDetails[0].profileImage)", subCount: "\(Int(viewModel.subCount[0].subscriberCount)!)", channelId: "\(viewModel.channelDetails[0].channelId)"))
                    .frame(width: 155, height: 155, alignment: .leading)
                    .opacity(self.animate ? 0 : 1)
                    .animation(.easeInOut(duration: 0.5))
                
                MediumWidget(entry: YouTubeChannel(channelName: "\(viewModel.channelDetails[0].channelName)", profileImage: "\(viewModel.channelDetails[0].profileImage)", subCount: "\(Int(viewModel.subCount[0].subscriberCount)!)", channelId: "\(viewModel.channelDetails[0].channelId)"))
                    .frame(width: 329, height: 155, alignment: .leading)
                    .opacity(self.animate ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5))
            }
            .rotation3DEffect(
                .degrees(rotateIn3D ? 12 : -12),
                axis: (x: rotateIn3D ? 90 : -45, y: rotateIn3D ? -45 : -90, z: 0))
            .animation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true))
            .onAppear() {
                rotateIn3D.toggle()
            }
              
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: UIScreen.main.bounds.width-40, height: 100, alignment: .center)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                VStack(spacing: 12) {
                    ZStack {
                        Rectangle()
                            .frame(width: UIScreen.main.bounds.width-47, height: 35, alignment: .center)
                            .foregroundColor(Color(UIColor.systemGray6))
                            .cornerRadius(16, corners: [.topLeft, .topRight])
                        Text("Preview")
                            .foregroundColor(Color(UIColor.label))
                            .font(.subheadline)
                            .bold()
                    }
                    Picker(selection: $widgetSize, label: Text("Select Size")) {
                        Text("Small").tag(0)
                        Text("Medium").tag(1)
                    }
                    .onChange(of: widgetSize, perform: { _ in
                        withAnimation {
                            animate.toggle()
                        }
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                    Spacer()
                        .frame(height: 3)
                }
            }
            
            Spacer()
        
        }
        .ignoresSafeArea(.keyboard)
        .background(Color(UIColor.systemGray6)).edgesIgnoringSafeArea(.all)
        .onAppear() {
            guard let channelId = try? JSONDecoder().decode(String.self, from: channelData) else {
                self.viewModel.getChannelDetails(for: "pewdiepie") { (success, channel)   in
                    if success {
                        guard let channelData = try? JSONEncoder().encode(channel!.channelId) else { return }
                        self.channelData = channelData
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                return
            }
            self.viewModel.getChannelDetails(for: channelId) { (success, _) in
                if !success {
                    self.showingAlert = true
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Unable to find channel"), message: Text("Please enter the correct channel username or ID"), primaryButton: .default(Text("Find my ID")) {
                openURL(URL(string: "https://commentpicker.com/youtube-channel-id.php")!)
            }, secondaryButton: .default(Text("OK")) {

            })
        }
    }
    
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

// extension for keyboard to dismiss
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

