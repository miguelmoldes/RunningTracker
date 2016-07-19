//
// Created by MIGUEL MOLDES on 18/7/16.
// Copyright (c) 2016 MIGUEL MOLDES. All rights reserved.
//

import Foundation
import UIKit

class RTActivitiesViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var activitiesModel : RTActivitiesModel!
    var activities:[RTActivity] = [RTActivity]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.activitiesModel = RTGlobalModels.sharedInstance.activitiesModel
        self.activities = self.activitiesModel.getActivities()
        setupTitle()
        setupTable()
    }

    func setupTitle() {
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.lineBreakMode = NSLineBreakMode.ByClipping
    }

    func setupTable() {
        self.tableView.registerNib(UINib(nibName:"RTActivityViewCell", bundle:nil), forCellReuseIdentifier: "activityViewCell")
        self.tableView.registerNib(UINib(nibName:"RTActivityHeaderViewCell", bundle:nil), forCellReuseIdentifier: "activityHeaderViewCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

// UITable delegate and source data

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activitiesModel.activitiesLenght()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell!
        if(indexPath.item == 0){
            cell = tableView.dequeueReusableCellWithIdentifier("activityHeaderViewCell", forIndexPath: indexPath) as! RTActivityHeaderViewCell
        }else{
            let activity = self.activities[indexPath.item - 1]
            cell = tableView.dequeueReusableCellWithIdentifier("activityViewCell", forIndexPath: indexPath) as! RTActivityViewCell
            (cell as! RTActivityViewCell).durationLabel.text = String(format:"%f", activity.distance)
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }

// IBActions

    @IBAction func backTouched(sender: UIButton) {
        self.navigationController!.popViewControllerAnimated(true)
    }

}