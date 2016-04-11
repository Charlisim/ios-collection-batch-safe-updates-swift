//
//  CSMCollectionUpdate.swift
//  CSMCollectionBatchUpdates
//
//  Created by Carlos Simon Villas on 11/04/16.
//  Copyright © 2016 Charlisim. All rights reserved.
//

import Foundation


public class CSMCollectionUpdate{
    let type:CSMCollectionUpdateType
    var object:AnyObject?
    var itemUpdate:Bool {
        get{
            return false
        }
    }
    var sectionUpdate:Bool{
        get{
            return false
        }
    }
    
    public init(withType type:CSMCollectionUpdateType, object:AnyObject){
        self.type = type
        self.object = object
    }
    
    public static func calculateUpdatesFor(
        oldModel oldSections:[CSMUpdatableCollectionSection]?,
        newModel newSections:[CSMUpdatableCollectionSection],
                 sectionsPriorityOrder:[String]?,
                 eliminatesDuplicates:Bool,
                 completion:(sections:[CSMUpdatableCollectionSection]?,
                            updates:[CSMCollectionUpdate]?)->Void
                 ){
        
        
        autoreleasepool {
            // Define section updates: UICollectionView and UITableView cannot deal with simultaneous updates for both items and sections (internal exceptions are generated leading to inconsistent states), so once a section change is detected perform full content reload instead of batch updates.
        
            // Find insertedSections
            
            for newIndex in 0..<newSections.count{
                let newSection:CSMUpdatableCollectionSection = newSections[newIndex]
                var oldIndex = NSNotFound
                
                if let oldSections = oldSections{
                    let matchedOldIndex = oldSections.indexOf({ (oldSection) -> Bool in
                        return oldSection.uid == newSection.uid

                    })
                    if matchedOldIndex == nil{
                        oldIndex = NSNotFound
                    }else if let newOldIndex = matchedOldIndex {
                        oldIndex = newOldIndex
                    }
                    if oldIndex == NSNotFound{
                        completion(sections: newSections, updates: nil)
                        return
                    }
                }
                
            }
            
            // Find deleted or moved sections
            if let oldSections = oldSections{
                for oldIndex in 0..<oldSections.count{
                    let oldSection = oldSections[oldIndex]
                    let newIndex = newSections.indexOf({ (newSection) -> Bool in
                        return oldSection.uid == newSection.uid
                        
                    })
                    
                    if oldIndex != newIndex{
                        completion(sections: newSections, updates: nil)
                        return
                    }
                }
            }
            
            // Calculate new sectionsProcessing order
            
            var newSectionsProcessingOrder:[Int] = []
            
            // First add index of priority order
            if let sectionsPriorityOrder = sectionsPriorityOrder{
                for sectionId in sectionsPriorityOrder{
                    let index = newSections.indexOf({ (newSection) -> Bool in
                        return newSection.uid == sectionId
                    })
                    if let index = index{
                        if !newSectionsProcessingOrder.contains(index){
                            newSectionsProcessingOrder.append(index)
                        }
                    }
                }
            }
            
            // Add the rest of index
            
            for sectionIndex in 0..<newSections.count{
                if !newSectionsProcessingOrder.contains(sectionIndex){
                    newSectionsProcessingOrder.append(sectionIndex)
                }
            }
            
            // Guarantee items uniqueness
            
            var newItemsSet:Set<String> = Set()
            for sectionIndex in newSectionsProcessingOrder{
                var newSection = newSections[sectionIndex]
                let notUniqueItemIndexes = NSMutableIndexSet()
                for (index, item) in newSection.items.enumerate(){
                    if newItemsSet.contains(item.uid){
                        notUniqueItemIndexes.addIndex(index)
                    }else{
                        newItemsSet.insert(item.uid)
                    }
                }
                var updatedItems = Array(newSection.items)
                for notUnique in notUniqueItemIndexes{
                    updatedItems.removeAtIndex(notUnique)
                }
                newSection.items = Array(updatedItems)
                if !eliminatesDuplicates{
                    newItemsSet.removeAll()
                }
            }
            
            // Pre-calculate new items indexPaths lookup table
            
            let newItemsLookupTable = NSMutableDictionary()
            for (section_index, newSection) in newSections.enumerate(){
                let newItemsInSection:NSMutableDictionary
                if eliminatesDuplicates{
                    newItemsInSection = newItemsLookupTable
                }else{
                    newItemsInSection = NSMutableDictionary()
                    newItemsLookupTable[newSection.uid] = newItemsInSection
                }
                
                for (item_index,item) in newSection.items.enumerate(){
                    newItemsInSection[item.uid] = NSIndexPath(forItem: item_index , inSection: section_index)
                }
            }
            
            
            // Pre-calculate old items indexPaths lookup table
            
            let oldItemsLookupTable = NSMutableDictionary()
            if let oldSections = oldSections{
                for (section_index, oldSection) in oldSections.enumerate(){
                    let oldItemsInSection:NSMutableDictionary
                    if eliminatesDuplicates{
                        oldItemsInSection = oldItemsLookupTable
                    }else{
                        oldItemsInSection = NSMutableDictionary()
                        newItemsLookupTable[oldSection.uid] = oldItemsInSection
                    }
                    
                    for (item_index,item) in oldSection.items.enumerate(){
                        oldItemsInSection[item.uid] = NSIndexPath(forItem: item_index , inSection: section_index)
                    }
                }
            }
            
            
            // Calculate updates
            
            var updates:[CSMCollectionUpdate] = []
            
            
            // Calculate inserted items
            for (section_index, newSection) in newSections.enumerate(){
                let lookupTable:NSDictionary
                if eliminatesDuplicates{
                    lookupTable = oldItemsLookupTable
                }else{
                    if let sectionData = oldItemsLookupTable[newSection.uid] as? NSDictionary{
                        lookupTable = sectionData
                    }else{
                        lookupTable = NSDictionary()
                    }
                }
                
                for (item_index, item) in newSection.items.enumerate(){
                    if let oldIndexPath:NSIndexPath? = lookupTable[item.uid] as? NSIndexPath{
                        if oldIndexPath == nil{
                            updates.append(CSMCollectionItemUpdate.updateWithType(.Insert, indexPath: nil, newIndexPath: NSIndexPath(forItem: item_index, inSection:section_index), object: item.uid))
                        }
                    }else{
                        updates.append(CSMCollectionItemUpdate.updateWithType(.Insert, indexPath: nil, newIndexPath: NSIndexPath(forItem: item_index, inSection:section_index), object: item.uid))
                    }
                    
                    
                }
                
            }
            
            // Calculate deleted and moved items
            
            var indexPathsForDeletedItems:[NSIndexPath] = []
            var indexPathsForMovedItems:[NSIndexPath] = []
            if let oldSections = oldSections{
                for (oldSection_index, oldSection) in oldSections.enumerate(){
                    let lookupTable:NSDictionary?
                    if eliminatesDuplicates{
                        lookupTable = newItemsLookupTable
                    }else{
                        lookupTable = newItemsLookupTable[oldSection.uid] as? NSDictionary
                    }
                    
                    for (item_index, item) in oldSection.items.enumerate(){
                        if let newIndexPath = lookupTable?[item.uid] as? NSIndexPath{
                            let newSection:CSMUpdatableCollectionSection = newSections[newIndexPath.section]
                            if newSection.uid == oldSection.uid && item_index == newIndexPath.item{
                                // Item remains at the same place
                                continue
                            }
                            let oldIndexPath = NSIndexPath(forItem: item_index, inSection: oldSection_index)
                            indexPathsForMovedItems.append(oldIndexPath)
                            updates.append(CSMCollectionItemUpdate(withType: .Move, object: item.uid, indexPath: oldIndexPath, newIndexPath: newIndexPath))
                            
                        }else{
                            let indexPath = NSIndexPath(forItem: item_index, inSection: oldSection_index)
                            indexPathsForDeletedItems.append(indexPath)
                            updates.append(CSMCollectionItemUpdate.updateWithType(.Delete, indexPath: nil, newIndexPath: indexPath, object: item.uid))
                        }
                    }
                }
            }
            
            // Calculates items to be reload
            
            if let oldSections = oldSections{
                for (section_index, oldSection) in oldSections.enumerate(){
                    let lookupTable:NSDictionary?
                    if eliminatesDuplicates{
                        lookupTable = newItemsLookupTable
                    }else{
                        lookupTable = newItemsLookupTable[oldSection.uid] as? NSDictionary
                    }
                    for (item_index, item) in oldSection.items.enumerate(){
                        // UITableView and UICollectionView have issues with updates for items which are being moved or deleted, so skip generation of such changes as according to tests moved items get updated during transition
                        let indexPath = NSIndexPath(forItem: item_index, inSection: section_index)
                        if indexPathsForDeletedItems.contains(indexPath)
                        || indexPathsForMovedItems.contains(indexPath){
                            continue
                        }
                        if let newIndexPath = lookupTable?[item.uid] as? NSIndexPath{
                            let newSection:CSMUpdatableCollectionSection = newSections[newIndexPath.section]
                            let newItem:CSMUpdatableCollectionItem = newSection.items[newIndexPath.item]
                            
                            if item.uid != newItem.uid{
                                updates.append(CSMCollectionItemUpdate.updateWithType(.Reload, indexPath: indexPath, newIndexPath: nil, object: item.uid))
                            }
                        }

                    }
                }

            }
            completion(sections: newSections, updates: updates)
        }
    }
    
}