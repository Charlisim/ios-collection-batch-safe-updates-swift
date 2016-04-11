//
//  UICollectionView+CSMBatchUpdates.swift
//  CSMCollectionBatchUpdates
//
//  Created by Carlos Simon Villas on 11/04/16.
//  Copyright © 2016 Charlisim. All rights reserved.
//

import Foundation


extension UICollectionView{
    
    func csm_performBatchUpdates(updates:[CSMCollectionUpdate],
                                 applyChangesToModelBlock:()->Void,
                                 reloadCellBlock:(cell:UICollectionViewCell, indexPath:NSIndexPath)->Void,
                                 completionBlock:(finished:Bool)->Void){
        if updates.isEmpty{
            applyChangesToModelBlock()
            self.reloadData()
            completionBlock(finished: true)
        }else{
            self.performBatchUpdates({ 
                applyChangesToModelBlock()
                
                for update in updates{
                    if let itemUpdate = update as? CSMCollectionItemUpdate{
                        self.updateItems(itemUpdate, reloadCellBlock: reloadCellBlock)
                    }
                    if let sectionUpdate = update as? CSMCollectionSectionUpdate{
                        self.updateSections(sectionUpdate)
                    }
                }
                }, completion: completionBlock)
        }
    }
    
    private func updateItems(itemUpdate:CSMCollectionItemUpdate, reloadCellBlock:(cell:UICollectionViewCell, indexPath:NSIndexPath)->Void){
        
        switch itemUpdate.type {
        case .Reload:
            if let indexPath = itemUpdate.indexPath, let cell = self.cellForItemAtIndexPath(indexPath){
                reloadCellBlock(cell: cell, indexPath: indexPath)
            }
            
        case .Delete:
            if let indexPath = itemUpdate.indexPath {
                self.deleteItemsAtIndexPaths([indexPath])
            }
        case .Insert:
            if let indexPath = itemUpdate.indexPathNew{
                self.insertItemsAtIndexPaths([indexPath])
            }
        case .Move:
            if let indexPath = itemUpdate.indexPathNew, let newIndexPath = itemUpdate.indexPathNew{
                self.moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)
            }

        }
    }
    private func updateSections(sectionUpdate:CSMCollectionSectionUpdate){
        switch sectionUpdate.type {
        case .Reload:
            self.reloadSections(NSIndexSet(index: sectionUpdate.sectionIndex))
            
            
        case .Delete:
            self.deleteSections(NSIndexSet(index: sectionUpdate.sectionIndex))
        
        case .Insert:
            self.insertSections(NSIndexSet(index: sectionUpdate.sectionIndexNew))
            
        case .Move:
            self.moveSection(sectionUpdate.sectionIndex, toSection: sectionUpdate.sectionIndexNew)
        }
    }
}