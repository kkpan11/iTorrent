//
//  PreferencesController.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02.09.2019.
//  Copyright © 2019  XITRIX. All rights reserved.
//

import UIKit

class PreferencesController : ThemedUIViewController {
    @IBOutlet var tableView: StaticTableView!
    var onScreenPopup : PopupView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var data = [StaticTableView.Section]()
        
        // APPEARENCE
        var appearence = [CellModelProtocol]()
        appearence.append(SegueCell.Model(self, title: "Settings.Order", segueViewId: "SettingsSortingController"))
        if #available(iOS 13, *) {
            appearence.append(SwitchCell.Model(title: "Settings.AutoTheme", defaultValue: { UserPreferences.autoTheme.value },
                                                       action: { switcher in
                                                        let oldTheme = Themes.current
                                                        UserPreferences.autoTheme.value = switcher.isOn
                                                        Themes.shared.currentUserTheme = UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle.rawValue
                                                        let newTheme = Themes.current

                                                        if (oldTheme != newTheme) {
                                                            self.navigationController?.view.isUserInteractionEnabled = false
                                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                                CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                                                                self.tableView.reloadData()
                                                                self.navigationController?.view.isUserInteractionEnabled = true
                                                            }
                                                        } else {
                                                            if let rvc = UIApplication.shared.keyWindow?.rootViewController as? Themed {
                                                                rvc.themeUpdate()
                                                            }
                                                            if (!switcher.isOn) {
                                                                self.tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                                                            }
                                                            else {
                                                                self.tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                                                            }
                                                        }
            }))
        }
        appearence.append(SwitchCell.Model(title: "Settings.Theme",
                                           defaultValue: { UserPreferences.themeNum.value == 1 },
                                           hiddenCondition: { UserPreferences.autoTheme.value }) { switcher in
                                            self.navigationController?.view.isUserInteractionEnabled = false
                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                                                UserPreferences.themeNum.value = switcher.isOn ? 1 : 0
                                                CircularAnimation.animate(startingPoint: switcher.superview!.convert(switcher.center, to: nil))
                                                self.navigationController?.view.isUserInteractionEnabled = true
                                            }
        })
        data.append(StaticTableView.Section(rowModels: appearence))
        
        //BACKGROUND
        var background = [CellModelProtocol]()
        background.append(SwitchCell.ModelProperty(title: "Settings.BackgroundEnable", property: UserPreferences.background) { _ in self.tableView.reloadData() })
        background.append(SwitchCell.Model(title: "Settings.BackgroundSeeding", defaultValue: { UserPreferences.backgroundSeedKey.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1), disableCondition: { !UserPreferences.background.value }){ switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("This will let iTorrent run in in the background indefinitely, in case any torrent is seeding without limits, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                    UserPreferences.backgroundSeedKey.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.seedBackgroundWarning.value = false
                UserPreferences.backgroundSeedKey.value = false
            }
        })
        data.append(StaticTableView.Section(rowModels: background, header: "Settings.BackgroundHeader", footer: "Settings.BackgroundFooter"))

        //SPEED LIMITATION
        var speed = [CellModelProtocol]()
        speed.append(ButtonCell.Model(title: "Settings.DownLimit",
                                      buttonTitle: UserPreferences.downloadLimit.value == 0 ?
                                        NSLocalizedString("Unlimited", comment: "") :
                                        Utils.getSizeText(size: UserPreferences.downloadLimit.value, decimals: true) + "/S")
        { button in
            self.onScreenPopup?.dismiss()
            self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.downloadLimit.value, dataSelected: { res in
                if (res == 0) {
                    button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                } else {
                    button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                }
            }, dismissAction: { res in
                UserPreferences.downloadLimit.value = res
                set_download_limit(Int32(res))
            })
            self.onScreenPopup?.show(self)
        })
        speed.append(ButtonCell.Model(title: "Settings.UpLimit",
                                      buttonTitle: UserPreferences.uploadLimit.value == 0 ?
                                        NSLocalizedString("Unlimited", comment: "") :
                                        Utils.getSizeText(size: UserPreferences.uploadLimit.value, decimals: true) + "/S")
        { button in
            self.onScreenPopup?.dismiss()
            self.onScreenPopup = SpeedPicker(defaultValue: UserPreferences.uploadLimit.value, dataSelected: { res in
                if (res == 0) {
                    button.setTitle(NSLocalizedString("Unlimited", comment: ""), for: .normal)
                } else {
                    button.setTitle(Utils.getSizeText(size: res, decimals: true) + "/S", for: .normal)
                }
            }, dismissAction: { res in
                UserPreferences.uploadLimit.value = res
                set_upload_limit(Int32(res))
            })
            self.onScreenPopup?.show(self)
        })
        data.append(StaticTableView.Section(rowModels: speed, header: "Settings.SpeedHeader"))

        //FTP
        var ftp = [CellModelProtocol]()
        ftp.append(SwitchCell.ModelProperty(title: "Settings.FTPEnable", property: UserPreferences.ftpKey) { switcher in
            switcher.isOn ? Manager.startFTP() : Manager.stopFTP()
            self.tableView.reloadData()
        })
        ftp.append(SwitchCell.Model(title: "Settings.FTPBackground", defaultValue: { UserPreferences.ftpBackgroundKey.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)) { switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("WARNING", comment: ""), message: NSLocalizedString("This will let iTorrent run in the background indefinitely, which can cause significant battery drain. \n\nYou will need to force close the app to stop this!", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .destructive) { _ in
                    UserPreferences.ftpBackgroundKey.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.ftpBackgroundKey.value = switcher.isOn
            }
        })
        data.append(StaticTableView.Section(rowModels: ftp, header: "Settings.FTPHeader", footerFunc: { () -> (String) in
            let addr = Utils.getWiFiAddress()
            if let addr = addr {
                let b = UserPreferences.ftpKey.value
                return b ? NSLocalizedString("Connect to: ftp://", comment: "") + addr + ":21" : ""
            } else {
                return NSLocalizedString("Connect to WIFI to use FTP", comment: "")
            }
        }))

        //NOTIFICATIONS
        var notifications = [CellModelProtocol]()
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyFinishLoad", property: UserPreferences.notificationsKey) { _ in self.tableView.reloadData() })
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyFinishSeed", property: UserPreferences.notificationsSeedKey) { _ in self.tableView.reloadData() })
        notifications.append(SwitchCell.ModelProperty(title: "Settings.NotifyBadge", property: UserPreferences.badgeKey, disableCondition: { !UserPreferences.notificationsKey.value && !UserPreferences.notificationsSeedKey.value }))
        data.append(StaticTableView.Section(rowModels: notifications, header: "Settings.NotifyHeader"))

        //UPDATES
        var updates = [CellModelProtocol]()
        updates.append(ButtonCell.Model(title: "Settings.UpdateSite", buttonTitle: "Settings.UpdateSite.Open") { button in
            Utils.openUrl("https://github.com/XITRIX/iTorrent")
        })
        updates.append(UpdateInfoCell.Model {
            self.present(Dialogs.crateUpdateDialog(forced: true)!, animated: true)
        })
        let version = try! String(contentsOf: Bundle.main.url(forResource: "Version", withExtension: "ver")!)
        data.append(StaticTableView.Section(rowModels: updates, header: "Settings.UpdateHeader", footer: NSLocalizedString("Current app version: ", comment: "") + version))

        //DONATES
        var donates = [CellModelProtocol]()
        donates.append(SegueCell.Model(title: "Settings.DonateCard.DonatePlatforms") {
            let alert = ThemedUIAlertController(title: Localize.get("Settings.DonateCard.DonatePlatforms.Title"), message: "", preferredStyle: .alert)

            let card = UIAlertAction(title: Localize.get("Settings.DonateCard"), style: .default) { _ in
                DispatchQueue.global(qos: .background).async {
                    if let url = URL(string: "https://raw.githubusercontent.com/XITRIX/iTorrent/master/iTorrent/Credit.card") {
                        var card = ""
                        do {
                            card = try String(contentsOf: url)
                        } catch {
                            card = "4817760222220562"
                        }

                        DispatchQueue.main.async {
                            UIPasteboard.general.string = card
                            let alert = ThemedUIAlertController(title: nil, message: NSLocalizedString("Copied CC # to clipboard!", comment: ""), preferredStyle: .alert)
                            self.present(alert, animated: true, completion: nil)
                            // change alert timer to 2 seconds, then dismiss
                            let when = DispatchTime.now() + 2
                            DispatchQueue.main.asyncAfter(deadline: when){
                                alert.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            let paypal = UIAlertAction(title: "PayPal", style: .default) { _ in
                Utils.openUrl("https://paypal.me/xitrix")
            }
            let patreon = UIAlertAction(title: "Patreon", style: .default) { _ in
                Utils.openUrl("https://www.patreon.com/xitrix")
            }
            let liberapay = UIAlertAction(title: "Liberapay", style: .default) { _ in
                Utils.openUrl("https://liberapay.com/XITRIX")
            }
            let kofi = UIAlertAction(title: "Ko-fi", style: .default) { _ in
                Utils.openUrl("https://ko-fi.com/xitrix")
            }
            let cancel = UIAlertAction(title: Localize.get("Cancel"), style: .cancel)

            alert.addAction(card)
            alert.addAction(paypal)
            alert.addAction(patreon)
            alert.addAction(liberapay)
            alert.addAction(kofi)
            alert.addAction(cancel)

            self.present(alert, animated: true)
        })
        donates.append(SwitchCell.Model(title: "Settings.DonateDisable", defaultValue: { UserPreferences.disableAds.value }, switchColor: #colorLiteral(red: 1, green: 0.2980392157, blue: 0.168627451, alpha: 1)) { switcher in
            if (switcher.isOn) {
                let controller = ThemedUIAlertController(title: NSLocalizedString("Supplication", comment: ""), message: NSLocalizedString("If you enjoy this app, consider supporting the developer by keeping the ads on.", comment: ""), preferredStyle: .alert)
                let enable = UIAlertAction(title: NSLocalizedString("Disable Anyway", comment: ""), style: .destructive) { _ in
                    UserPreferences.disableAds.value = switcher.isOn
                }
                let close = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    switcher.setOn(false, animated: true)
                }
                controller.addAction(enable)
                controller.addAction(close)
                self.present(controller, animated: true)
            } else {
                UserPreferences.disableAds.value = switcher.isOn
            }
        })
        data.append(StaticTableView.Section(rowModels: donates, header: "Settings.DonateHeader"))
        
        tableView.data = data
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onScreenPopup?.dismiss()
    }
}
