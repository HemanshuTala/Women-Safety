const User = require('../models/User');
const SOS = require('../models/SOS');
const ConnectionRequest = require('../models/ConnectionRequest');

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('parents', 'name phone role')
      .populate('children', 'name phone role');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// Parent requests to connect to a child by childPhone
exports.requestConnect = async (req, res) => {
  try {
    const parent = req.user;
    const { childPhone, message } = req.body;
    const child = await User.findOne({ phone: childPhone });
    if (!child) return res.status(404).json({ message: 'Child not found' });

    if (child.parents.includes(parent._id)) {
      return res.status(400).json({ message: 'Already connected' });
    }

    const existing = await ConnectionRequest.findOne({ requester: parent._id, target: child._id, status: 'pending' });
    if (existing) return res.status(400).json({ message: 'Request already pending' });

    const reqDoc = await ConnectionRequest.create({
      requester: parent._id,
      target: child._id,
      message: message || ''
    });

    // Optional: emit socket to child so they get notified (if online)
    // io.to(`user_socket_${child._id}`).emit('connection:request', reqDoc);

    res.json({ success: true, request: reqDoc });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// Child lists incoming requests
exports.listRequests = async (req, res) => {
  try {
    const user = req.user;
    const requests = await ConnectionRequest.find({ target: user._id, status: 'pending' })
      .populate('requester', 'name phone');
    res.json(requests);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

// Child accepts/rejects a request
exports.respondRequest = async (req, res) => {
  try {
    const user = req.user; // child
    const { id } = req.params; // id of request
    const { action } = req.body; // 'accept' or 'reject'

    const reqDoc = await ConnectionRequest.findById(id);
    if (!reqDoc) return res.status(404).json({ message: 'Request not found' });
    if (reqDoc.target.toString() !== user._id.toString()) return res.status(403).json({ message: 'Not authorized' });
    if (reqDoc.status !== 'pending') return res.status(400).json({ message: 'Already responded' });

    if (action === 'accept') {
      const parent = await User.findById(reqDoc.requester);
      if (!parent) return res.status(404).json({ message: 'Parent user not found' });

      if (!user.parents.includes(parent._id)) user.parents.push(parent._id);
      if (!parent.children.includes(user._id)) parent.children.push(user._id);

      await user.save();
      await parent.save();

      reqDoc.status = 'accepted';
      reqDoc.respondedAt = new Date();
      await reqDoc.save();

      return res.json({ success: true, message: 'Accepted', request: reqDoc });
    } else {
      reqDoc.status = 'rejected';
      reqDoc.respondedAt = new Date();
      await reqDoc.save();
      return res.json({ success: true, message: 'Rejected', request: reqDoc });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.disconnectParent = async (req, res) => {
  try {
    const { childId } = req.body;
    const parent = req.user;

    parent.children = parent.children.filter(id => id.toString() !== childId);
    await parent.save();

    const child = await User.findById(childId);
    if (child) {
      child.parents = child.parents.filter(id => id.toString() !== parent._id.toString());
      await child.save();
    }

    res.json({ message: 'Disconnected' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getSosHistory = async (req, res) => {
  try {
    const { userId } = req.params; // optional - defaults to current user
    const target = userId || req.user._id;
    const sos = await SOS.find({ user: target }).sort({ createdAt: -1 }).limit(100);
    res.json(sos);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
