//
//  ContentView.swift
//  darling-nikki
//
//  Created by Douglas Purdy on 1/24/20.
//  Copyright © 2020 Zendo Tools. All rights reserved.
//

import SwiftUI

struct ZensorView: View
{
    @ObservedObject var model : Zensor
    
    var body: some View
    {
        HStack
            {
                
                VStack {
                    
                    Image(systemName: "dot.radiowaves.right").padding(5)
                    Text(model.name).font(.system(size: 10)).bold()
                }
                
                
                VStack {
                    
                    Image(systemName: "stopwatch").padding(5)
                    Text(model.duration).font(.system(size: 10)).bold()
                }
                
                VStack {
                    Image(systemName: "gauge").padding(5)
                    Text(model.samples.count.description).font(.system(size: 10)).bold()
                }
                
                VStack {
                    Image(systemName: "heart").padding(5)
                    Text(model.hr.prefix(4)).font(.system(size: 10)).bold()
                    
                }
                
                
                               VStack {
                                   
                                   Image(systemName: "arrow.up").padding(5)
                                   Text(model.isInBreath.description).font(.system(size: 10)).bold()
                                   
                               }
                               
                               
                               VStack {
                                   
                                   Image(systemName: "arrow.down").padding(5)
                                   Text(model.isOutBreath.description).font(.system(size: 10)).bold()
                                   
                               }
                
                VStack {
                    Image(systemName: "waveform.path.ecg").padding(5)
                    Text(model.hrv).font(.system(size: 10)).bold()
                    
                }
                
                VStack {
                    
                    Image(systemName: "eye.fill").padding(5)
                    Text(model.isMeditating.description).font(.system(size: 10)).bold()
                    
                }
                
                VStack {
                    
                    Image(systemName: "list.number").padding(5)
                    Text(model.level.description).font(.system(size: 10)).bold()
                    
                }
        }
    }
}
